defmodule Noa.Tokens.ACGrant do
  @moduledoc false

  alias Ecto.{Changeset, Multi}
  alias Noa.Tokens.{AC, AT, RT, Scopes}
  alias Noa.{Repo, Actors.Providers}

  @spec issue_access_token(AC.t) :: {:ok, AT.t, nil | RT.t} | {:error, atom}
  def issue_access_token(%AC{} = code) do
    case code |> transaction_ops() |> Repo.transaction() do
      {:ok, %{access_token: atoken, refresh_token: rtoken}} -> {:ok, atoken, rtoken}
      _ -> {:error, :store_failure}
    end
  end

  defp transaction_ops(%AC{} = code) do
    provider = Providers.lookup(code.provider_id)
    scope_master_list = Scopes.get_all(provider)

    computed_scope = code.scope
    |>  String.split()
    |>  MapSet.new()
    |>  MapSet.intersection(scope_master_list)
    |>  Enum.join(" ")

    attrs = %{provider_id: code.provider_id, issued_to: code.issued_to, authz_code_id: code.id,
              scope: computed_scope, expires_in: provider.refresh_token_ttl}
    cs = %RT{} |> RT.create_cs(attrs)
    Multi.new()
    |> Multi.insert(:refresh_token, cs)
    |> Multi.run(:access_token, fn changes ->
        %RT{} = token = Map.get(changes, :refresh_token)
        code
        |>  Changeset.cast(%{exchanged_on: DateTime.utc_now()}, [:exchanged_on])
        |>  Repo.update()
        attrs = %{
          provider_id: token.provider_id,
          issued_to: token.issued_to,
          authz_code_id: token.authz_code_id,
          refresh_token_id: token.id,
          scope: token.scope,
          expires_in: provider.access_token_ttl
        }
        %AT{} |> AT.create_cs(attrs, %{grant_type: :authorization_code}) |> Repo.insert()
       end)
  end
end
