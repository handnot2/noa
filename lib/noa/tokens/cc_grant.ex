defmodule Noa.Tokens.CCGrant do
  alias Ecto.Multi
  alias Noa.Tokens.{AT, RT, Scopes}
  alias Noa.{Repo, Actors.Providers}

  @spec issue_access_token(map) :: {:ok, AT.t, nil | RT.t} | {:error, atom}
  def issue_access_token(%{provider_id: provider_id, client_id: client_id,
        scope: scope}) do
    scope_master_list = provider_id
    |>  Providers.lookup()
    |>  Scopes.get_all()

    computed_scope = scope
    |>  String.split()
    |>  MapSet.new()
    |>  MapSet.intersection(scope_master_list)
    |>  Enum.join(" ")

    attrs = %{
      "provider_id" => provider_id,
      "issued_to" => client_id,
      "scope" => computed_scope
    }
    case attrs |> transaction_ops() |> Repo.transaction() do
      {:ok, %{access_token: atoken}} -> {:ok, atoken, nil}
      e -> IO.inspect(e, label: "store_failure");{:error, :store_failure}
    end
  end

  defp transaction_ops(%{} = attrs) do
    cs = %AT{} |> AT.create_cs(attrs, %{grant_type: :client_credentials})
    Multi.new() |> Multi.insert(:access_token, cs)
  end
end
