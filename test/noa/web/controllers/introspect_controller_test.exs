defmodule Noa.Web.IntrospectControllerTest do
  use Noa.Web.ConnCase
  import Noa.{NoaHelper}

  setup %{conn: conn} do
    conn = conn |> put_req_header("accept", "application/json")
    seed_test_context(conn: conn)
  end

  defp assert_token_inactive(conn) do
    resp = json_response(conn, 200)
    assert Map.get(resp, "active") == false
  end

  test "lookup - access_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {atoken, _rtoken} = issue_tokens(pr1, cl1, "rs1owner")
    atoken_stub = atoken |> get_stub("access_token")

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => atoken_stub,
    }

    conn = post conn, introspect_path(conn, :introspect, pr1.id, attrs)
    resp = json_response(conn, 200)
    assert Map.get(resp, "active") == true
    assert Map.get(resp, "client_id") == atoken.issued_to
    assert Map.get(resp, "scope") == atoken.scope
    assert Map.get(resp, "iat") == atoken.issued_on |> DateTime.to_unix()
    assert Map.get(resp, "exp") == atoken.expires_on |> DateTime.to_unix()
  end

  test "lookup - invalid access_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {atoken_stub, _rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => atoken_stub <> "a",
    }

    post(conn, introspect_path(conn, :introspect, pr1.id, attrs))
    |>  assert_token_inactive()
  end

  test "lookup - missing access_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    rs1 = rs1(ctxt)
    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
    }

    post(conn, introspect_path(conn, :introspect, pr1.id, attrs))
    |>  assert_token_inactive()
  end

  test "lookup - refresh_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {_atoken, rtoken} = issue_tokens(pr1, cl1, "rs1owner")
    rtoken_stub = rtoken |> get_stub("refresh_token")

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => rtoken_stub,
      "token_type_hint" => "refresh_token",
    }

    conn = post conn, introspect_path(conn, :introspect, pr1.id, attrs)
    resp = json_response(conn, 200)
    assert Map.get(resp, "active") == true
    assert Map.get(resp, "client_id") == rtoken.issued_to
    assert Map.get(resp, "scope") == rtoken.scope
    assert Map.get(resp, "iat") == rtoken.issued_on |> DateTime.to_unix()
    assert Map.get(resp, "exp") == rtoken.expires_on |> DateTime.to_unix()
  end

  test "lookup - invalid refresh_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {_atoken_stub, rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => rtoken_stub <> "a",
      "token_type_hint" => "refresh_token",
    }

    post(conn, introspect_path(conn, :introspect, pr1.id, attrs))
    |>  assert_token_inactive()
  end

  test "lookup - missing refresh_token", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    rs1 = rs1(ctxt)
    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token_type_hint" => "refresh_token",
    }

    post(conn, introspect_path(conn, :introspect, pr1.id, attrs))
    |>  assert_token_inactive()
  end
end
