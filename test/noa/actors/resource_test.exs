defmodule Noa.Actors.ResourceTest do
  use Noa.DataCase

  alias Noa.Actors.{Resource}

  test "create resource" do
    attrs = %{
      "name" => "app1",
      "secret" => "app1secret",
      "scope" => "read write delete"
    }

    cs = %Resource{} |> Resource.create_cs(attrs)
    assert cs.valid?
  end
end
