defmodule NoaWeb.RevokeController do
  @moduledoc false

  use NoaWeb, :controller
  action_fallback NoaWeb.FallbackController

  alias Noa.Actors.{Registrar}
  alias NoaWeb.{TokenUtils}

  def revoke(conn, %{} = attrs) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    stub = Map.get(attrs, "token", "")
    token_type = Map.get(attrs, "token_type_hint", "access_token")
    with  {:ok, token} <- TokenUtils.get_validated_token(stub, token_type),
          :ok <- TokenUtils.check_validity_period(token),
          :ok <- TokenUtils.check_revocation_status(token),
          :ok <- check_mismatched_token(token, noa_ctxt)
    do
      Registrar.revoke(token)
      conn |> put_status(200) |> json(%{"revoked" => true})
    else
      _e -> conn |> put_status(200) |> json(%{"revoked" => true})
    end
  rescue
    e -> {:error, :server_error, "#{inspect e}"}
  end

  defp check_mismatched_token(%{provider_id: id}, %{provider: %{id: id}}), do: :ok
  defp check_mismatched_token(_, _), do: {:error, :invalid_token, "mismatch"}
end
