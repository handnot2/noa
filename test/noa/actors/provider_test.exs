defmodule Noa.Actors.ProviderTest do
  use Noa.DataCase

  alias Noa.Actors.{Provider}

  test "create provider" do
    attrs = %{
      "desc" => "provider for dev",
      "scope" => "read write delete"
    }

    cs = %Provider{} |> Provider.create_cs(attrs)
    assert cs.valid?
  end

  test "invalid access_token_ttl" do
    attrs = %{"access_token_ttl" => 0}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?

    attrs = %{"access_token_ttl" => -10}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?

    attrs = %{"access_token_ttl" => 100, "refresh_token_ttl" => 50}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?
  end

  test "invalid refresh_token_ttl" do
    attrs = %{"refresh_token_ttl" => 0}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?

    attrs = %{"refresh_token_ttl" => -10}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?

    attrs = %{"access_token_ttl" => 100, "refresh_token_ttl" => 100}
    cs = %Provider{} |> Provider.create_cs(attrs)
    refute cs.valid?
  end
end
