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
end
