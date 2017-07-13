defmodule Noa.Web.Plugs.ProviderLoader do
  @moduledoc false

  import Plug.Conn
  require Logger
  alias Noa.Actors.{Provider, Providers}

  def init(opts), do: opts

  def call(conn, _opts) do
    %{"provider_id" => provider_id} = conn.path_params
    case Providers.lookup(provider_id) do
      %Provider{} = provider -> conn |> add_to_ctxt(provider)
      _ ->
        conn
        |>  put_resp_header("content-type", "application/json")
        |>  send_resp(400, ~s({"error": "invalid_request"}))
        |>  halt()
    end
  rescue
    _ ->
      conn
      |>  put_resp_header("content-type", "application/json")
      |>  send_resp(500, ~s({"error": "server_error"}))
      |>  halt()
  end

  defp add_to_ctxt(conn, provider) do
    ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    conn |> assign(:noa_ctxt, Map.put(ctxt, :provider, provider))
  end
end
