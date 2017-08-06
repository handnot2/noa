defmodule NoaWeb.RevokeControllerTest do
  use NoaWeb.ConnCase
  import Noa.{NoaHelper}
  alias Noa.Actors.Registrar
  alias Noa.Tokens.{AT, RT}

  setup %{conn: conn} do
    conn = conn |> put_req_header("accept", "application/json")
    seed_test_context(conn: conn)
  end

  test "revoke - access_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    #rs1 = rs1(ctxt)
    {atoken, _rtoken} = issue_tokens(pr1, cl1, "rs1owner")
    atoken_stub = atoken |> get_stub("access_token")

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "token"         => atoken_stub,
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)

    token = Registrar.lookup(atoken.id, "access_token")
    assert %AT{revoked_on: %DateTime{}} = token
  end

  test "revoke - refresh_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    #rs1 = rs1(ctxt)
    {_atoken, rtoken} = issue_tokens(pr1, cl1, "rs1owner")
    rtoken_stub = rtoken |> get_stub("refresh_token")

    attrs = %{
      "client_id"       => cl1.id,
      "client_secret"   => cl1.name,
      "token"           => rtoken_stub,
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)

    token = Registrar.lookup(rtoken.id, "refresh_token")
    assert %RT{revoked_on: %DateTime{}} = token
  end

  test "revoke - invalid access_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    #rs1 = rs1(ctxt)
    {atoken_stub, _rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
      "token"         => atoken_stub <> "a",
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - invalid refresh_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    #rs1 = rs1(ctxt)
    {_atoken_stub, rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "client_id"       => cl1.id,
      "client_secret"   => cl1.name,
      "token"           => rtoken_stub <> "a",
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - missing access_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    attrs = %{
      "client_id"     => cl1.id,
      "client_secret" => cl1.name,
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - missing refresh_token from client", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    attrs = %{
      "client_id"       => cl1.id,
      "client_secret"   => cl1.name,
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - access_token from RS", %{conn: conn} = ctxt do
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

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)

    token = Registrar.lookup(atoken.id, "access_token")
    assert %AT{revoked_on: %DateTime{}} = token
  end

  test "revoke - refresh_token from RS", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {_atoken, rtoken} = issue_tokens(pr1, cl1, "rs1owner")
    rtoken_stub = rtoken |> get_stub("refresh_token")

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => rtoken_stub,
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)

    token = Registrar.lookup(rtoken.id, "refresh_token")
    assert %RT{revoked_on: %DateTime{}} = token
  end

  test "revoke - invalid access_token from RS", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {atoken_stub, _rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => atoken_stub <> "a",
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - invalid refresh_token from RS", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    cl1 = cl1(ctxt)
    rs1 = rs1(ctxt)
    {_atoken_stub, rtoken_stub} = issue_tokens(pr1, cl1, "rs1owner") |> get_token_stubs()

    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token"           => rtoken_stub <> "a",
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - missing access_token from RS", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    rs1 = rs1(ctxt)
    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end

  test "revoke - missing refresh_token from RS", %{conn: conn} = ctxt do
    pr1 = pr1(ctxt)
    rs1 = rs1(ctxt)
    attrs = %{
      "resource_id"     => rs1.id,
      "resource_secret" => rs1.name,
      "token_type_hint" => "refresh_token"
    }

    conn = post conn, revoke_path(conn, :revoke, pr1.id, attrs)
    assert json_response(conn, 200)
  end
end
