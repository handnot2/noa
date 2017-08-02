defmodule NoaWeb.Plugs.EnsureAuthenticated do
  @moduledoc false

  import Plug.Conn
  alias Ueberauth.Auth

  def init(opts \\ []), do: opts

  def call(conn, [:resource_owner]) do
    case get_session(conn, "x-noa-az-ro") do
      %Auth{} -> conn
      _ -> redirect_for_auth(conn)
    end
  end

  def call(conn, opts) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    if opts |> Enum.any?(&(Map.has_key?(noa_ctxt, &1))) do
      conn
    else
      conn
      |>  put_resp_header("content-type", "application/json")
      |>  send_resp(401, ~s({"error": "invalid_client"}))
      |>  halt()
    end
  end

  defp redirect_for_auth(conn) do
    auth_uri = NoaWeb.Router.Helpers.idrp_path(NoaWeb.Endpoint, :request, "noa")
    auth_state = gen_auth_state()
    conn
    |>  put_session("x-noa-az-stage", "auth")
    |>  put_session("x-noa-az-state-auth", auth_state)
    |>  Phoenix.Controller.redirect(to: auth_uri <> "?state=#{auth_state}")
    |>  halt()
  end

  defp gen_auth_state(), do: :crypto.strong_rand_bytes(30) |> Base.url_encode64()
end
