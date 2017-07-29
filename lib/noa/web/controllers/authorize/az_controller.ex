defmodule Noa.Web.Authorize.AzController do
  use Noa.Web, :controller
  action_fallback Noa.Web.FallbackController

  import Noa.Web.Router.Helpers, only: [consent_path: 3]
  alias Noa.Web.Authorize.AzReq

  def authorize(conn, %{} = params) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    cs = AzReq.authorize_cs(params, noa_ctxt)
    if cs.valid? do
      consent_state = gen_consent_state()
      provider = noa_ctxt[:provider]
      consent_uri = consent_path(Noa.Web.Endpoint, :show_consent, provider.id)
      conn
      |>  fetch_session()
      |>  configure_session(renew: true)
      |>  put_session("x-noa-authz-req-data", cs.changes)
      |>  put_resp_cookie("x-noa-az-consent-state", consent_state)
      |>  redirect(to: consent_uri <> "?state=#{consent_state}")
    else
      # TODO: proper error handling
      {:error, cs}
    end
  end

  defp gen_consent_state(), do: :crypto.strong_rand_bytes(30) |> Base.url_encode64()
end
