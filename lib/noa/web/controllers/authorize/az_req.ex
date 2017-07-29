defmodule Noa.Web.Authorize.AzReq do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset, as: CS
  alias Noa.Actors.{Client, Clients}

  embedded_schema do
    field :client_id
    field :response_type
    field :redirect_uri
    field :scope
    field :state
    field :provider
    field :client
    field :approved_scope
  end

  @required_fields [:client_id, :response_type]
  @optional_fields [:redirect_uri, :scope, :state]

  def authorize_cs(%{} = params, %{} = noa_ctxt) do
    %Noa.Web.Authorize.AzReq{}
    |>  cast(params, @required_fields ++ @optional_fields)
    |>  validate_required(@required_fields)
    |>  validate_inclusion(:response_type, ["code", "token"])
    |>  validate_client(noa_ctxt)
    |>  validate_redirect_uri(noa_ctxt)
    |>  setup_provider(noa_ctxt)
  end

  defp validate_client(%CS{valid?: false} = cs, _noa_ctxt), do: cs
  defp validate_client(cs, _noa_ctxt) do
    case cs |> get_change(:client_id) |> Clients.lookup() do
      %Client{} = client -> cs |> put_change(:client, client)
      _ -> cs |> add_error(:client_id, "invalid_client")
    end
  end

  defp validate_redirect_uri(%CS{valid?: false} = cs, _noa_ctxt), do: cs
  defp validate_redirect_uri(%CS{changes: %{redirect_uri: guri}} = cs, _noa_ctxt) do
    client = cs |> get_change(:client)
    if guri in client.uris, do: cs, else: cs |> add_error(:redirect_uri, "invalid")
  end
  defp validate_redirect_uri(cs, _noa_ctxt) do
    client = cs |> get_change(:client)
    cs |> put_change(:redirect_uri, client.uris |> hd())
  end

  defp setup_provider(cs, %{provider: provider}) do
    cs |> put_change(:provider, provider)
  end
end
