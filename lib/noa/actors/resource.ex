defmodule Noa.Actors.Resource do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, UUID, autogenerate: true}
  schema "resources" do
    field :name, :string
    field :secret_hash, :string
    field :scope, :string
    field :provider_id, :string

    timestamps()
  end

  def create_cs(resource, attrs) do
    resource
    |> cast(attrs, [:name, :scope, :provider_id])
    |> validate_required([:name, :scope])
    |> validate_secret(Map.get(attrs, "secret"), required: true)
  end

  def update_cs(resource, attrs) do
    resource
    |> cast(attrs, [:scope])
    |> validate_secret(Map.get(attrs, "secret"), required: false)
  end

  defp validate_secret(cs, nil, required: false), do: cs
  defp validate_secret(cs, nil, required: true), do: Changeset.add_error(cs, :secret, "missing")
  defp validate_secret(cs, secret, _) do
    cond do
      String.length(secret) < 5 -> Changeset.add_error(cs, :secret, "minimum size 5")
      cs.valid? == false -> cs
      true ->
        secret_hash = Comeonin.Bcrypt.hashpwsalt(secret)
        cs |> Changeset.put_change(:secret_hash, secret_hash)
    end
  end
end
