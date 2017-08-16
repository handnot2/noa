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
    http_only: true,
    # TODO
    #secure: true,
    signing_salt: System.get_env("NOA_SESSION_SIGNING_SALT") || "1WtpgHQ0"

  plug NoaWeb.Router

  @doc """
  Dynamically loads configuration from the system environment
  on startup.

  It receives the endpoint configuration from the config files
  and must return the updated configuration.
  """
  def init(_key, config) do
    if config[:load_from_system_env], do: load_runtime_config!(config), else: {:ok, config}
  end

  defp load_runtime_config!(config) do
    host = System.get_env("NOA_HOST") || "localhost"
    ssl_config  = ssl_config!()
    http_config = http_config!()

    if http_config == nil && ssl_config == nil do
      raise "Error: Port missing - define env var NOA_PORT and/or NOA_SSL_PORT"
    end

    config = config |> Keyword.put(:url, [host: host])
    config = if ssl_config do
      config |> Keyword.put(:https, ssl_config)
    else
      config |> Keyword.put(:http, http_config)
    end

    {:ok, config}
  end

  defp http_config!() do
    case port!("NOA_PORT") do
      :undefined -> nil
      _port -> Application.get_env(:noa, :http_config, [])
    end
  end

  defp ssl_config!() do
    case port!("NOA_SSL_PORT") do
      :undefined -> nil
      _port -> Application.get_env(:noa, :ssl_config, [])
    end
  end

  defp port!(ev_name) do
    ev_value = System.get_env(ev_name)
    if ev_value do
      case Integer.parse(ev_value || "") do
        {port, ""} when port > 0 -> port
        _ -> raise "Error: Invalid #{ev_name}"
      end
    else
      :undefined
    end
  end
end
