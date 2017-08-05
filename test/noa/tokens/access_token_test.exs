defmodule Noa.Tokens.AccessTokenTest do
  use Noa.DataCase

  alias Ecto.{UUID}
  alias Noa.Actors.{Registrar, Providers}
  alias Noa.Tokens.{AC, AT, RT}
  alias Noa.{Tokens}
  import Noa.{NoaHelper}

  setup _context do
    seed_test_context()
  end

  defp access_token_from_ccgrant(pr, cl, scope) do
    {:ok, atoken, nil} = %{provider_id: pr.id, client_id: cl.id, scope: scope}
    |>  Registrar.issue_access_token()
    atoken
  end

  defp access_token_from_acgrant(pr, cl, res_owner) do
    {:ok, atoken, rtoken} =
      claims(pr, cl, res_owner)
      |>  authorization_code()
      |>  Registrar.issue_access_token()
    {atoken, rtoken}
  end

  test "issue - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    assert atoken.authz_code_id == nil
    assert atoken.refresh_token_id == nil
  end

  test "issue - client_credentials_grant - check ttl", ctxt do
    ttls = %{"access_token_ttl" => 100, "refresh_token_ttl" => 200}
    {:ok, pr} = pr1(ctxt) |> Providers.update(ttls)
    atoken = access_token_from_ccgrant(pr, cl1(ctxt), "p1_read rs1:perm1")
    assert atoken.authz_code_id == nil
    assert atoken.refresh_token_id == nil
    assert Tokens.expires_in(atoken) == 100
  end

  test "issue - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    refute atoken.issued_to == nil
    refute atoken.refresh_token_id == nil

    assert %AC{exchanged_on: %DateTime{}} = Tokens.lookup(AC, atoken.authz_code_id)
  end

  test "issue - authorization_code_grant - ttl check", ctxt do
    ttls = %{"access_token_ttl" => 100, "refresh_token_ttl" => 200}
    {:ok, pr} = pr1(ctxt) |> Providers.update(ttls)
    {atoken, rtoken} = access_token_from_acgrant(pr, cl1(ctxt), "rs1owner")
    refute atoken.issued_to == nil
    refute atoken.refresh_token_id == nil
    assert Tokens.expires_in(rtoken) == 200
    assert Tokens.expires_in(atoken) == 100

    assert %AC{exchanged_on: %DateTime{}} = Tokens.lookup(AC, atoken.authz_code_id)
  end

  test "revoke - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    assert atoken.revoked_on == nil
    assert {:ok, %AT{revoked_on: %DateTime{}}} = Registrar.revoke_access_token(atoken)
  end

  test "revoke - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert atoken.revoked_on == nil
    assert {:ok, %AT{revoked_on: %DateTime{}}} = Registrar.revoke_access_token(atoken)
    assert %RT{revoked_on: nil} = Tokens.lookup(RT, atoken.refresh_token_id)
  end

  test "lookup - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    assert %AT{issued_on: %DateTime{}, revoked_on: nil} = Tokens.lookup(AT, atoken.id)
  end

  test "lookup - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert %AT{issued_on: %DateTime{}, revoked_on: nil} = Tokens.lookup(AT, atoken.id)
  end

  test "lookup non-existent access_token" do
    refute Tokens.lookup(AT, UUID.generate())
  end

  test "delete - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    assert Tokens.delete(atoken)
  end

  test "delete - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(atoken)
  end

  test "delete deleted - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    assert Tokens.delete(atoken)
    assert_raise Ecto.StaleEntryError, fn -> Tokens.delete(atoken) end
  end

  test "delete deleted - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(atoken)
    assert_raise Ecto.StaleEntryError, fn -> Tokens.delete(atoken) end
  end

  test "delete non-existent access_token" do
    assert_raise Ecto.StaleEntryError, fn -> %AT{id: UUID.generate()} |> Tokens.delete() end
  end

  test "reap - client_credentials_grant", ctxt do
    atoken = access_token_from_ccgrant(pr1(ctxt), cl1(ctxt), "p1_read rs1:perm1")
    expired_on_or_before = relative_to_utc(60 * 60 * 1000, :later)
    assert {:ok, count} = Tokens.reap(AT, expired_on_or_before: expired_on_or_before)
    assert count > 0
    refute Tokens.lookup(AT, atoken.id)
  end

  test "reap - authorization_code_grant", ctxt do
    {atoken, _rtoken} = access_token_from_acgrant(pr1(ctxt), cl1(ctxt), "rs1owner")
    expired_on_or_before = relative_to_utc(60 * 60 * 1000, :later)
    assert {:ok, count} = Tokens.reap(AT, expired_on_or_before: expired_on_or_before)
    assert count > 0
    refute Tokens.lookup(AT, atoken.id)
  end
end
