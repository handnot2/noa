defmodule NoaWeb.Plugs.DisableRespCache do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts), do: register_before_send(conn, &disable_resp_caching/1)

  defp disable_resp_caching(conn) do
    conn
    |> delete_resp_header("cache-control")
    |> put_resp_header("cache-control", "no-cache, no-store")
    |> delete_resp_header("pragma")
    |> put_resp_header("pragma", "no-cache")
  end
end
