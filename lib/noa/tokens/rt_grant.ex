defmodule Noa.Tokens.RTGrant do
  @moduledoc false

  alias Ecto.Multi
  alias Noa.Actors.{Providers}
  alias Noa.Tokens.{AT, RT}
  alias Noa.{Repo}

  @spec issue_access_token(RT.t) :: {:ok, AT.t, nil | RT.t} | {:error, atom}
  def issue_access_token(%RT{} = rtoken) do
    case rtoken |> transaction_ops() |> Repo.transaction() do
      {:ok, %{access_token: atoken}} -> {:ok, atoken, rtoken}
      _ -> {:error, :store_failure}
    end
  end

  defp transaction_ops(%RT{} = token) do
    provider = Providers.lookup(token.provider_id)
    attrs = %{
      "provider_id" => token.provider_id,
      "issued_to" => token.issued_to,
      "authz_code_id" => token.authz_code_id,
      "refresh_token_id" => token.id,
      "scope" => token.scope,
      "access_token_ttl" => provider.access_token_ttl
    }

    cs = %AT{} |> AT.create_cs(attrs, %{grant_type: :refresh_token})
    Multi.new() |> Multi.insert(:access_token, cs)
  end
end
