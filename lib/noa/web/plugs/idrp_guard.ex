defmodule Noa.Web.Plugs.IdrpGuard do
  @moduledoc false

  import Plug.Conn

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    idrp_state = conn.cookies["x-noa-idrp-state"]
    case {conn.params["state"], idrp_state} do
      {nil, _} ->
        halt_request(conn, {403, ~s({"error": "forbidden", "error_description": "idrpg-1"})})
      {_, nil} ->
        halt_request(conn, {403, ~s({"error": "forbidden", "error_description": "idrpg-2"})})
      {state, state} -> conn
      _ ->
        halt_request(conn, {403, ~s({"error": "state_mismatch", "error_description": "idrpg-3"})})
    end
  end

  defp halt_request(conn, {status, message}) do
    conn
    |>  put_resp_header("content-type", "application/json")
    |>  send_resp(status, message)
    |>  halt()
  end
end
