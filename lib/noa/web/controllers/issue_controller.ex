defmodule Noa.Web.IssueController do
  @moduledoc false

  use Noa.Web, :controller
  action_fallback Noa.Web.FallbackController

  alias Noa.Tokens.{StubHandler, Scopes, AC, AT, RT}
  alias Noa.{Actors.Registrar, Tokens}
  alias Noa.Web.{TokenUtils}

  def issue(conn, %{} = attrs) do
    case issue_(conn, attrs) do
      {:ok, at, rt} ->
        resp = %{} |> issue_resp_at(at) |> issue_resp_rt(rt)
        conn |> put_status(200) |> json(resp)
      error -> error
    end
  rescue
    e -> {:error, :server_error, "#{inspect e}"}
  end

  defp issue_(conn, %{"grant_type" => "authorization_code", "code" => code}) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    with {:ok, token} <- validated_token_from_grant("authorization_code", code, noa_ctxt)
    do
      Registrar.issue_access_token(token)
    end
  end
  defp issue_(conn, %{"grant_type" => "refresh_token", "token" => token}) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    with {:ok, token} <- validated_token_from_grant("refresh_token", token, noa_ctxt)
    do
      Registrar.issue_access_token(token)
    end
  end
  defp issue_(conn, %{"grant_type" => "client_credentials", "scope" => scope}) do
    %{client: client, provider: prov} = noa_ctxt = Map.get(conn.assigns, :noa_ctxt)
    with  {:ok, scope} <- validated_scope(scope, noa_ctxt),
          grant = %{client_id: client.id, provider_id: prov.id, scope: scope}
    do
      Registrar.issue_access_token(grant)
    end
  end
  defp issue_(_conn, %{"grant_type" => _}), do: {:error, :unsupported_grant_type}
  defp issue_(_conn, _), do: {:error, :invalid_request}

  defp validated_token_from_grant(grant_type, token_stub, %{client: client, provider: prov}) do
    with  {:ok, token} <- TokenUtils.get_validated_token(token_stub, grant_type),
          :ok <- check_mismatched_token(token, client, prov),
          :ok <- multiuse_or_unused_grant(token),
          :ok <- TokenUtils.check_validity_period(token),
          :ok <- TokenUtils.check_revocation_status(token)
    do
      {:ok, token}
    end
  end

  defp check_mismatched_token(
          %{issued_to: client_id, provider_id: provider_id} = _token,
          %{id: client_id} = _client,
          %{id: provider_id} = _provider), do: :ok
  defp check_mismatched_token(_token, _client, _provider), do: {:error, :invalid_grant}

  defp multiuse_or_unused_grant(%RT{}), do: :ok
  defp multiuse_or_unused_grant(%AC{exchanged_on: nil}), do: :ok
  defp multiuse_or_unused_grant(%AC{}), do: {:error, :invalid_grant}

  @spec validated_scope(binary, map) :: {:ok, binary} | {:error, atom, binary}
  defp validated_scope("", noa_ctxt), do: noa_ctxt[:client].scope
  defp validated_scope(scope, %{provider: prov}) do
    prov_scopes = Scopes.get_all(prov)
    if valid_scope?(scope, prov_scopes), do: {:ok, scope}, else: {:error, :invalid_scope}
  end

  defp valid_scope?(scope, available_scopes) do
    scope |> String.split() |> MapSet.new() |> MapSet.subset?(available_scopes)
  end

  defp issue_resp_at(%{} = resp, %AT{} = at) do
    exp = Tokens.expires_in(at)
    {:ok, stub} = StubHandler.encode_stub("access_token", at.id)
    Map.merge(resp, %{access_token: stub, token_type: "Bearer", expires_in: exp})
  end

  defp issue_resp_rt(%{} = resp, nil), do: resp
  defp issue_resp_rt(%{} = resp, %RT{} = rt) do
    exp = Tokens.expires_in(rt)
    {:ok, stub} = StubHandler.encode_stub("refresh_token", rt.id)
    resp |> Map.put(:refresh_token, stub) |> Map.put(:refresh_token_expires_in, exp)
  end
end
