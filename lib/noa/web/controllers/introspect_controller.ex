defmodule Noa.Web.IntrospectController do
  use Noa.Web, :controller
  action_fallback Noa.Web.FallbackController

  alias Noa.Web.{TokenUtils}

  def lookup(conn, %{} = attrs) do
    %{client: client, provider: prov} = Map.get(conn.assigns, :noa_ctxt)
    stub = Map.get(attrs, "token", "")
    token_type = Map.get(attrs, "token_type_hint", "access_token")
    with  {:ok, token} <- TokenUtils.get_validated_token(stub, token_type),
          :ok <- TokenUtils.check_validity_period(token),
          :ok <- TokenUtils.check_revocation_status(token),
          :ok <- check_mismatched_token(prov, token, client)
    do
      resp = lookup_resp(token)
      conn |> put_status(200) |> json(resp)
    else
      _e -> conn |> put_status(200) |> json(%{"active" => false})
    end
  rescue
    e -> {:error, :server_error, "#{inspect e}"}
  end

  # TODO: introduce audience check
  defp check_mismatched_token(%{id: provider_id} = _provider,
          %{provider_id: provider_id, issued_to: token_client_id} = _token,
          %{id: req_client_id} = _client) do
    cond do
      token_client_id == req_client_id -> :ok
      true -> {:error, :invalid_token, "mismatch"}
    end
  end
  defp check_mismatched_token(_provider, _token, _client) do
    {:error, :invalid_token, "mismatch"}
  end

  defp lookup_resp(token) do
    iat = DateTime.to_unix(token.issued_on)
    exp = DateTime.to_unix(token.expires_on)
    %{
      active: true, scope: token.scope, client_id: token.issued_to,
      iat: iat, nbf: iat, exp: exp,
    }
  end
end
