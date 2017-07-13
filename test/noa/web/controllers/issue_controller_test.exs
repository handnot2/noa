defmodule Noa.Web.IssueControllerTest do
  use Noa.Web.ConnCase
  alias Noa.Tokens.{Scopes}
  import Noa.{NoaHelper}

  setup %{conn: conn} do
    conn = conn |> put_req_header("accept", "application/json")
    seed_test_context(conn: conn)
  end

  defp assert_token_ok_resp(conn, opts \\ []) do
    resp = json_response(conn, 200)
    assert Map.get(resp, "access_token") != nil
    assert Map.get(resp, "expires_in") > 0
    assert Map.get(resp, "token_type") == "Bearer"
    if Keyword.get(opts, :refresh_token, true) do
      assert Map.get(resp, "refresh_token") != nil
    else
      assert Map.get(resp, "refresh_token") == nil
    end
  end

  test "invalid provider id", %{conn: conn} do
    post(conn, issue_path(conn, :issue, "invalid_provider", %{}))
    |>  assert_token_error_resp(400, "invalid_request")
  end

  test "invalid client_id", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    attrs = %{
      "client_id"     => "invalid_client_id",
      "client_secret" => "invalid secret",
      "grant_type"    => "client_credentials",
      "scope"         => "read write",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(401, "invalid_client")
  end

  test "invalid secret", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => "invalid secret",
      "grant_type"    => "client_credentials",
      "scope"         => Scopes.get(rs1) |> Enum.join(" "),
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(401, "invalid_client")
  end

  test "issue - invalid grant_type", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "wrong_grant_type",
      "scope"         => "read write",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(400, "unsupported_grant_type")
  end

  test "issue - client_credentials grant", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "client_credentials",
      "scope"         => "p1_read rs1:perm3",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_ok_resp(refresh_token: false)
  end

  test "issue - client_credentials grant invalid scope", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "client_credentials",
      "scope"         => "invalid_scope",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(400, "invalid_scope")
  end

  test "issue - authorization_code grant", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    stub = issue_code(pr1, cl1, "rs1owner") |> get_stub("authorization_code")

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "authorization_code",
      "code"          => stub,
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_ok_resp()
  end

  test "issue - authorization_code grant invalid", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    stub = issue_code(pr1, cl1, "rs1owner") |> get_stub("authorization_code")

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "authorization_code",
      "code"          => stub <> "a",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(400, "invalid_grant")
  end

  test "issue - refresh_token grant", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    {_atoken_stub, rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "refresh_token",
      "token"         => rtoken_stub,
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_ok_resp()
  end

  test "issue - refresh_token grant invalid token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    {_atoken_stub, rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "grant_type"    => "refresh_token",
      "token"         => rtoken_stub <> "a",
    }

    post(conn, issue_path(conn, :issue, pr1.id, attrs))
    |>  assert_token_error_resp(400, "invalid_grant")
  end
end
