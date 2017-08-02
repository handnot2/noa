defmodule Noa.Web.Plugs.ResourceAuthenticator do
  @moduledoc false

  import Plug.Conn
  require Logger
  alias Comeonin.Bcrypt
  alias Noa.Actors.{Resource, Resources}

  def init(opts), do: opts

  def call(conn, _opts) do
    resource_id = Map.get(conn.params, "resource_id")
    resource_secret = Map.get(conn.params, "resource_secret")
    res = authenticated_resource(resource_id, resource_secret)
    if res, do: conn |> add_to_ctxt(res), else: conn
  rescue
    e ->
      conn
      |>  put_resp_header("content-type", "application/json")
      |>  send_resp(500, ~s({"error": "server_error #{inspect e}"}))
      |>  halt()
  end

  defp authenticated_resource(nil, nil), do: nil
  defp authenticated_resource(id, secret) do
    case Resources.lookup(id || "") do
      %Resource{} = res ->
        if Bcrypt.checkpw(secret || "", res.secret_hash),
          do: res,
        else: nil
      _ -> Bcrypt.dummy_checkpw(); nil
    end
  end

  defp add_to_ctxt(conn, res) do
    ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    conn |> assign(:noa_ctxt, Map.put(ctxt, :resource, res))
  end
end
