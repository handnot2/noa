defmodule NoaWeb.ConsentController do
  @moduledoc false

  use NoaWeb, :controller

  import NoaWeb.Router.Helpers, only: [consent_path: 3]
  import Noa.Actors.Registrar, only: [issue_access_token: 1, issue_authorization_code: 1]
  alias Noa.Tokens
  alias Noa.Tokens.{AC, AT, StubHandler, Scopes}

  def show_consent(conn, %{} = params) do
    noa_ctxt     = Map.get(conn.assigns, :noa_ctxt, %{})
    reqdata      = get_session(conn, "x-noa-authz-req-data") || %{}
    provider     = Map.get(reqdata, :provider)
    client       = Map.get(reqdata, :client)
    redirect_uri = Map.get(reqdata, :redirect_uri)
    scope        = Map.get(reqdata, :scope) || client.scope || ""
    scope_set    = scope |> String.split() |> MapSet.new()

    with  :ok <- stage_match(get_stage(conn)),
          :ok <- provider_match(noa_ctxt, provider),
          {:ok, approval_scope_set} <- scope_for_approval(provider, scope_set, false)
    do
      posturi = consent_path(NoaWeb.Endpoint, :show_consent, provider.id)
      approval_scope = approval_scope_set |> MapSet.to_list() |> Enum.join(" ")
      reqdata = Map.put(reqdata, :approval_scope, approval_scope)
      opts    = [params: params, scopes: approval_scope_set, client_name: client.name,
                 redirect_uri: redirect_uri, consent_uri: posturi]
      conn
      |>  put_resp_header("x-csrf-token", get_csrf_token())
      |>  put_session("x-noa-authz-req-data", reqdata)
      |>  put_status(200)
      |>  render("consent.html", opts)
    else
      {:error, :invalid_scope} ->
        send_authz_error_resp(conn, reqdata, %{error: "invalid_scope", error_description: scope})
      {:error, error} when error in [:stage_mismatch, :provider_mismatch] ->
        desc = "ncc-1 #{inspect error}"
        send_http_error_resp(conn, 403, %{error: :forbidden, error_description: desc})
      error ->
        desc = "ncc-2 #{inspect error}"
        send_http_error_resp(conn, 403, %{error: :forbidden, error_description: desc})
    end
  rescue
    error ->
      desc = "ncc-3 #{inspect error}"
      send_http_error_resp(conn, 500, %{error: "server_error", error_description: desc})
  end

  def consent(conn, %{} = params) do
    noa_ctxt = Map.get(conn.assigns, :noa_ctxt, %{})
    reqdata  = get_session(conn, "x-noa-authz-req-data") || %{}
    provider = Map.get(reqdata, :provider)

    with  :ok <- stage_match(get_stage(conn)),
          :ok <- provider_match(noa_ctxt, provider),
          :ok <- check_consent(params)
    do
      conn |> send_authz_response(reqdata)
    else
      {:error, :access_denied} ->
        desc = "request rejected"
        send_authz_error_resp(conn, reqdata, %{error: "access_denied", error_description: desc})
      {:error, error} when error in [:stage_mismatch, :provider_mismatch] ->
        desc = "ncc-4 #{inspect error}"
        send_http_error_resp(conn, 403, %{error: :forbidden, error_description: desc})
    end
  rescue
    error ->
      desc = "ncc-3 #{inspect error}"
      send_http_error_resp(conn, 500, %{error: "server_error", error_description: desc})
  end

  defp send_authz_response(conn, %{} = reqdata) do
    %{redirect_uri: uri, approval_scope: scope} = reqdata
    state = Map.get(reqdata, :state)
    case gen_code_token(conn, reqdata) do
      {:ok, code_token} ->
        resp_data = code_token_data(code_token, scope)
        full_uri = full_redirect_uri(uri, resp_data, state, query_or_fragment?(reqdata))
        conn |> cleanup_session() |> redirect(external: full_uri)
      {:error, msg} ->
        send_authz_error_resp(conn, reqdata, %{error: "server_error", error_description: msg})
    end
  end

  defp send_authz_error_resp(conn, %{redirect_uri: uri} = reqdata, %{} = error) do
    state = Map.get(reqdata, :state)
    error_data = error |> Enum.map(fn {k, v} -> {k, to_string(v)} end)
    full_uri = full_redirect_uri(uri, error_data, state, query_or_fragment?(reqdata))
    conn |> cleanup_session() |> redirect(external: full_uri)
  end

  defp send_http_error_resp(conn, status, error_json) do
    conn
    |>  cleanup_session()
    |>  put_status(status)
    |>  json(error_json)
  end

  defp cleanup_session(conn) do
    conn
    |>  configure_session(drop: true)
  end

  defp gen_code_token(conn, %{response_type: "code"} = reqdata) do
    auth = get_session(conn, "x-noa-az-ro")

    claims = %{
      "provider_id"   => reqdata.provider.id,
      "issued_to"     => reqdata.client.id,
      "authorized_by" => auth.uid,
      "authorized_on" => DateTime.utc_now(),
      "redirect_uri"  => reqdata.redirect_uri,
      "scope"         => reqdata.approval_scope,
    }

    case claims |> issue_authorization_code() do
      {:ok, code} -> {:ok, code}
      error -> {:error, "#{inspect error}"}
    end
  end

  defp gen_code_token(_conn, %{response_type: "token"} = reqdata) do
    %{client: cl, provider: pr, approval_scope: scope} = reqdata
    case issue_access_token(%{client_id: cl.id, provider_id: pr.id, scope: scope}) do
      {:ok, atoken, _} -> {:ok, atoken}
      error -> {:error, "#{inspect error}"}
    end
  end

  defp code_token_data(%AC{} = code, _scope) do
    {:ok, stub} = StubHandler.encode_stub("authorization_code", code.id)
    [code: stub]
  end

  defp code_token_data(%AT{} = token, scope) do
    {:ok, stub} = StubHandler.encode_stub("authorization_code", token.id)
    expires_in  = Tokens.expires_in(token)
    [access_token: stub, expires_in: expires_in, scope: scope]
  end

  defp full_redirect_uri(redirect_uri, resp_data, state, query_or_fragment)
          when query_or_fragment in [:query, :fragment] do
    encoded_data = resp_data
    |>  Keyword.merge(if state, do: [state: state], else: [])
    |>  Plug.Conn.Query.encode()

    redirect_uri
    |>  URI.parse()
    |>  Map.put(query_or_fragment, encoded_data)
    |>  URI.to_string()
  end

  defp query_or_fragment?(%{response_type: "code"}), do: :query
  defp query_or_fragment?(%{response_type: "token"}), do: :fragment

  defp scope_for_approval(provider, requested_scope_set, ignore_unknown) do
    approval_scope_set = MapSet.intersection(Scopes.get_all(provider), requested_scope_set)
    size = MapSet.size(approval_scope_set)
    if size == 0 || (ignore_unknown == false && MapSet.size(requested_scope_set) != size) do
      {:error, :invalid_scope}
    else
      {:ok, approval_scope_set}
    end
  end

  defp get_stage(conn), do: get_session(conn, "x-noa-authz-stage") || "consent"

  defp stage_match("consent"), do: :ok
  defp stage_match(_), do: {:error, :stage_mismatch}

  defp provider_match(%{provider: %{id: id}}, %{id: id}), do: :ok
  defp provider_match(_, _), do: {:error, :provider_mismatch}

  defp check_consent(%{"authorization" => "authorized"}), do: :ok
  defp check_consent(_), do: {:error, :access_denied}
end
