defmodule Noa.Web.Plugs.ROAuthGuard do
  @moduledoc false

  import Plug.Conn
  alias Ueberauth.Auth

  def init(opts \\ []), do: opts

  def call(%{method: "POST"} = conn, _opts), do: conn

  def call(conn, _opts) do
    with  :ok <- valid_state?(conn),
          {:ok, _auth} <- signedin_user(conn)
    do
      conn |> delete_resp_cookie("x-noa-az-consent-state")
    else
      {:error, :invalid_state} ->
        desc = "azroap-1"
        halt_request(conn, {403, ~s({"error": "forbidden", "error_description": #{desc}})})

      {:error, :unauthenticated} ->
        idrp_uri = Noa.Web.Router.Helpers.idrp_path(Noa.Web.Endpoint, :request, "noa")
        idrp_state = gen_idrp_state()
        conn
        |>  put_resp_cookie("x-noa-idrp-state", idrp_state)
        |>  Phoenix.Controller.redirect(to: idrp_uri <> "?state=#{idrp_state}")
        |>  halt()

      error ->
        desc = "azroap-2 #{inspect error}"
        halt_request(conn, {403, ~s({"error": "forbidden", "error_description": #{desc}})})
    end
  end

  defp halt_request(conn, {status, message}) do
    conn
    |>  put_resp_header("content-type", "application/json")
    |>  send_resp(status, message)
    |>  halt()
  end

  defp valid_state?(conn) do
    case {Map.get(conn.params, "state"), conn.cookies["x-noa-az-consent-state"]} do
      {nil, _} -> {:error, :invalid_state}
      {_, nil} -> {:error, :invalid_state}
      {state, state} -> :ok
      _ -> {:error, :invalid_state}
    end
  end

  defp signedin_user(conn) do
    case get_session(conn, "x-noa-az-ro") do
      %Auth{} = auth -> {:ok, auth}
      _ -> {:error, :unauthenticated}
    end
  end

  defp gen_idrp_state(), do: :crypto.strong_rand_bytes(30) |> Base.url_encode64()
end
