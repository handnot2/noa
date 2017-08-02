defmodule NoaWeb.IntrospectController do
  @moduledoc false

  use NoaWeb, :controller
  action_fallback NoaWeb.FallbackController

  alias Noa.Tokens.{Scopes}
  alias NoaWeb.{TokenUtils}

  def introspect(conn, %{} = attrs) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    stub = Map.get(attrs, "token", "")
    token_type = Map.get(attrs, "token_type_hint", "access_token")
    with  {:ok, token} <- TokenUtils.get_validated_token(stub, token_type),
          :ok <- TokenUtils.check_validity_period(token),
          :ok <- TokenUtils.check_revocation_status(token),
          :ok <- check_mismatched_token(token, noa_ctxt)
    do
      resp = introspect_resp(token, compute_scope(token.scope, noa_ctxt))
      conn |> put_status(200) |> json(resp)
    else
      _e -> conn |> put_status(200) |> json(%{"active" => false})
    end
  rescue
    e -> {:error, :server_error, "#{inspect e}"}
  end

  defp check_mismatched_token(%{provider_id: id}, %{provider: %{id: id}}), do: :ok
  defp check_mismatched_token(_, _), do: {:error, :invalid_token, "mismatch"}

  defp compute_scope(token_scope, %{provider: prov, resource: res}) when res != nil do
    token_scope
    |>  String.split()
    |>  MapSet.new()
    |>  MapSet.intersection(Scopes.get(prov, [res]))
  end

  defp compute_scope(token_scope, %{provider: prov, client: client}) when client != nil do
    token_scope
    |> String.split()
    |>  MapSet.new()
    |>  MapSet.intersection(Scopes.get_all(prov))
  end

  defp compute_scope(_, _), do: MapSet.new()

  defp introspect_resp(token, computed_scope) do
    if MapSet.size(computed_scope) == 0 do
      %{active: false}
    else
      iat = DateTime.to_unix(token.issued_on)
      exp = DateTime.to_unix(token.expires_on)
      %{
        active: true, scope: token.scope, client_id: token.issued_to,
        iat: iat, nbf: iat, exp: exp,
      }
    end
  end
end
