defmodule NoaWeb.AuthorizeController do
  @moduledoc false

  use NoaWeb, :controller
  action_fallback NoaWeb.FallbackController

  import NoaWeb.Router.Helpers, only: [consent_path: 3]
  alias NoaWeb.AuthorizeReq

  def authorize(conn, %{} = params) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    cs = AuthorizeReq.authorize_cs(params, noa_ctxt)
    if cs.valid? do
      consent_state = gen_consent_state()
      provider = noa_ctxt[:provider]
      consent_uri = consent_path(NoaWeb.Endpoint, :show_consent, provider.id)
      conn
      |>  fetch_session()
      |>  configure_session(renew: true)
      |>  put_session("x-noa-authz-req-data", cs.changes)
      |>  put_session("x-noa-az-stage", "consent")
      |>  put_session("x-noa-az-state-consent", consent_state)
      |>  redirect(to: consent_uri <> "?state=#{consent_state}")
    else
      # TODO: proper error handling
      {:error, cs}
    end
  end

  defp gen_consent_state(), do: :crypto.strong_rand_bytes(30) |> Base.url_encode64()
end
