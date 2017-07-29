defmodule Noa.Web.Idrp.IdrpController do
  use Noa.Web, :controller
  action_fallback Noa.Web.FallbackController

  import Noa.Web.Router.Helpers, only: [consent_path: 3]

  def request(conn, _attrs), do: conn

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _attrs) do
    desc = "idrpc-1 #{inspect failure}"
    conn
    |>  delete_resp_cookie("x-noa-idrp-state")
    |>  put_status(401)
    |>  json(%{error: "signin_failed", error_description: desc})
    |>  halt()
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _attrs) do
    provider = get_session(conn, "x-noa-authz-req-data") |> get_in([:provider])
    consent_uri = consent_path(Noa.Web.Endpoint, :show_consent, provider.id)
    consent_state = conn.cookies["x-noa-az-consent-state"]
    conn
    |>  delete_resp_cookie("x-noa-idrp-state")
    |>  put_session("x-noa-az-ro", auth)
    |>  redirect(to: consent_uri <> "?state=#{consent_state}")
  end
end
