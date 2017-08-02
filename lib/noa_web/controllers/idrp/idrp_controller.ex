defmodule NoaWeb.IdrpController do
  @moduledoc false

  use NoaWeb, :controller
  action_fallback NoaWeb.FallbackController

  import NoaWeb.Router.Helpers, only: [consent_path: 3]

  def request(conn, _attrs), do: conn

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _attrs) do
    desc = "idrpc-1 #{inspect failure}"
    conn
    |>  delete_session("x-noa-az-state-auth")
    |>  put_status(401)
    |>  json(%{error: "signin_failed", error_description: desc})
    |>  halt()
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _attrs) do
    provider = get_session(conn, "x-noa-authz-req-data") |> get_in([:provider])
    consent_uri = consent_path(NoaWeb.Endpoint, :show_consent, provider.id)
    consent_state = get_session(conn, "x-noa-az-state-consent")
    conn
    |>  delete_session("x-noa-az-state-auth")
    |>  put_session("x-noa-az-ro", auth)
    |>  put_session("x-noa-az-stage", "consent")
    |>  redirect(to: consent_uri <> "?state=#{consent_state}")
  end

  def callback(conn, _attrs) do
    desc = "server_error"
    conn
    |>  delete_session("x-noa-az-state-auth")
    |>  put_status(500)
    |>  json(%{error: "signin_failed", error_description: desc})
    |>  halt()
  end
end
