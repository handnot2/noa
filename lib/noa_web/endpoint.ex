defmodule NoaWeb.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :noa

  socket "/socket", NoaWeb.UserSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :noa, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_noa_key",
    max_age: 60 * 60,
    signing_salt: System.get_env("NOA_SIGNING_SALT") || "1WtpgHQ0"

  plug NoaWeb.Router

  @doc """
  Dynamically loads configuration from the system environment
  on startup.

  It receives the endpoint configuration from the config files
  and must return the updated configuration.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      if System.get_env("NOA_PORT") == nil &&
          System.get_env("NOA_SSL_PORT") == nil do
        raise "Error: Port missing - define env var NOA_PORT and/or NOA_SSL_PORT"
      end

      host = System.get_env("NOA_HOST") || "localhost"

      config = [url: [host: host], http: http_config!(), https: https_config!()]
      |>  Enum.reject(fn {_k, v} -> length(v) == 0 end)
      |>  Enum.reduce(config, fn {k, v}, config -> Keyword.put(config, k, v) end)

      {:ok, config}
    else
      {:ok, config}
    end
  end

  defp http_config!() do
    case port(System.get_env("NOA_PORT")) do
      :undefined -> []
      {:error, :invalid} -> raise "Error: Invalid NOA_PORT"
      {:ok, port} -> [:inet6, port: port]
    end
  end

  defp https_config!() do
    case port(System.get_env("NOA_SSL_PORT")) do
      :undefined -> []
      {:error, :invalid} -> raise "Error: Invalid NOA_SSL_PORT"
      {:ok, _port} ->
        Application.get_env(:noa, :ssl_config, [])
    end
  end

  defp port(nil), do: :undefined
  defp port(value) do
    case Integer.parse(value) do
      {port, ""} when port > 0 -> {:ok, port}
      _ -> {:error, :invalid}
    end
  end
end
