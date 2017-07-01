defmodule Noa.Tokens.ACGrant do
  alias Ecto.{Changeset, Multi}
  alias Noa.Tokens.{AC, AT, RT}
  alias Noa.{Repo}

  @spec issue_access_token(AC.t) :: {:ok, AT.t, nil | RT.t} | {:error, atom}
  def issue_access_token(%AC{} = code) do
    case code |> transaction_ops() |> Repo.transaction() do
      {:ok, %{access_token: atoken, refresh_token: rtoken}} -> {:ok, atoken, rtoken}
      _ -> {:error, :store_failure}
    end
  end

  defp transaction_ops(%AC{} = code) do
    attrs = %{provider_id: code.provider_id, issued_to: code.issued_to,
              authz_code_id: code.id,  scope: code.scope}
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
        }
        %AT{} |> AT.create_cs(attrs, %{grant_type: :authorization_code}) |> Repo.insert()
       end)
  end
end
