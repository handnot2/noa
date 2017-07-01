defmodule Noa.Web.Plugs.ClientAuthenticator do
  @moduledoc false

  import Plug.Conn
  require Logger
  alias Comeonin.Bcrypt
  alias Noa.Actors.{Client, Clients}

  def init(opts), do: opts

  def call(conn, _opts) do
    %{"client_id" => client_id, "secret" => secret} = conn.params
    case Clients.lookup(client_id) do
      %Client{} = client ->
        case Bcrypt.checkpw(secret, client.secret_hash) do
          true -> conn |> add_to_ctxt(client)
          _    -> conn |> send_resp(401, ~s({"error": "invalid_client"})) |> halt()
        end
      _ ->
        Bcrypt.dummy_checkpw()
        conn |> send_resp(401, ~s({"error": "invalid_client"})) |> halt()
    end
  rescue
    _ -> conn |> send_resp(500, ~s({"error": "server_error"})) |> halt()
  end

  defp add_to_ctxt(conn, client) do
    ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    conn |> assign(:noa_ctxt, Map.put(ctxt, :client, client))
  end
end
