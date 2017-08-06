defmodule Noa.Tokens.RefreshTokenTest do
  use Noa.DataCase

  alias Ecto.{UUID}
  alias Noa.Actors.{Registrar}
  alias Noa.Tokens.{RT}
  alias Noa.{Tokens}
  import Noa.{NoaHelper}

  setup _context do
    seed_test_context()
  end

  test "issue access_token - refresh_token_grant", ctxt do
    {atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    result = Registrar.issue_access_token(rtoken)
    assert {:ok, atoken1, ^rtoken} = result
    refute atoken.id == atoken1.id
    assert atoken1.revoked_on == nil
  end

  test "revoke", ctxt do
    {_atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert rtoken.revoked_on == nil
    assert {:ok, %RT{revoked_on: %DateTime{}}} = Registrar.revoke(rtoken)
  end

  test "lookup", ctxt do
    {_atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.lookup(RT, rtoken.id)
  end

  test "lookup non-existent refresh_token" do
    refute Tokens.lookup(RT, UUID.generate())
  end

  test "delete", ctxt do
    {_atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(rtoken)
  end

  test "delete deleted", ctxt do
    {_atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(rtoken)
    assert_raise Ecto.StaleEntryError, fn -> Tokens.delete(rtoken) end
  end

  test "delete non-existent" do
    assert_raise Ecto.StaleEntryError, fn -> %RT{id: UUID.generate()} |> Tokens.delete() end
  end

  test "reap", ctxt do
    {_atoken, rtoken} = issue_tokens(pr1(ctxt), cl1(ctxt), "rs1owner")
    expired_on_or_before = relative_to_utc(60 * 60 * 1000, :later)
    assert {:ok, count} = Tokens.reap(RT, expired_on_or_before: expired_on_or_before)
    assert count > 0
    refute Tokens.lookup(RT, rtoken.id)
  end
end
