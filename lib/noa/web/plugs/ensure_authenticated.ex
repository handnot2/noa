defmodule Noa.Web.Plugs.EnsureAuthenticated do
  @moduledoc false

  import Plug.Conn

  def init(opts \\ []), do: opts

  def call(conn, opts) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    if opts |> Enum.any?(&(Map.has_key?(noa_ctxt, &1))) do
      conn
    else
      conn |> send_resp(401, ~s({"error": "invalid_client"})) |> halt()
    end
  end
end
