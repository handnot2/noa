defmodule Noa.Web.Plugs.ClientAuthenticator do
  @moduledoc false

  import Plug.Conn
  require Logger
  alias Comeonin.Bcrypt
  alias Noa.Actors.{Client, Clients}

  def init(opts), do: opts

  def call(conn, _opts) do
    client_id = Map.get(conn.params, "client_id")
    client_secret = Map.get(conn.params, "client_secret")
    client = authenticated_client(client_id, client_secret)
    if client, do: conn |> add_to_ctxt(client), else: conn
  rescue
    _ ->
      conn
      |>  put_resp_header("content-type", "application/json")
      |>  send_resp(500, ~s({"error": "server_error"}))
      |>  halt()
  end

  defp authenticated_client(nil, nil), do: nil
  defp authenticated_client(id, secret) do
    case Clients.lookup(id || "") do
      %Client{} = client ->
        if Bcrypt.checkpw(secret || "", client.secret_hash),
          do: client,
        else: nil
      _ -> Bcrypt.dummy_checkpw(); nil
    end
  end

  defp add_to_ctxt(conn, client) do
    ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    conn |> assign(:noa_ctxt, Map.put(ctxt, :client, client))
  end
end
