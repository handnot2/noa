defmodule Noa.Tokens.AuthzCodeTest do
  use Noa.DataCase

  alias Ecto.{UUID}
  alias Noa.Actors.{Registrar}
  alias Noa.Tokens.{AC}
  alias Noa.{Tokens}
  import Noa.{NoaHelper}

  setup _context do
    seed_test_context()
  end

  test "issue code", ctxt do
    assert issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
  end

  test "revoke code", ctxt do
    code = issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert {:ok, %AC{revoked_on: %DateTime{}}} = Registrar.revoke(code)
  end

  test "lookup code", ctxt do
    code = issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.lookup(AC, code.id)
  end

  test "lookup non-existent code" do
    refute Tokens.lookup(AC, UUID.generate())
  end

  test "delete code", ctxt do
    code = issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(code)
  end

  test "delete non-existent code" do
    assert_raise Ecto.StaleEntryError, fn -> %AC{id: UUID.generate()} |> Tokens.delete() end
  end

  test "delete already deleted code", ctxt do
    code = issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
    assert Tokens.delete(code)
    assert_raise Ecto.StaleEntryError, fn -> Tokens.delete(code) end
  end

  test "reap code", ctxt do
    code = issue_code(pr1(ctxt), cl1(ctxt), "rs1owner")
    expired_on_or_before = relative_to_utc(60 * 60 * 1000, :later)
    assert {:ok, count} = Tokens.reap(AC, expired_on_or_before: expired_on_or_before)
    assert count > 0
    refute Tokens.lookup(AC, code.id)
  end
end
