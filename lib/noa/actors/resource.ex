defmodule Noa.Actors.Resource do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{UUID}

  @primary_key {:id, UUID, autogenerate: true}
  schema "resources" do
    field :name, :string
    field :scope, :string
    field :owner_id, UUID
    field :enc_token_secret, :string

    timestamps()
  end

  def create_cs(resource, attrs) do
    resource
    |> cast(attrs, [:name, :scope, :owner_id])
    |> validate_required([:name, :scope])
  end

  def update_cs(resource, attrs) do
    resource
    |> cast(attrs, [:enc_token_secret])
  end

  def update_secret_cs(res, secret) do
    # TODO: encrypted_secret = Vault.encrypt("resources", secret)
    encrypted_secret = secret
    update_cs(res, %{"enc_token_secret" => encrypted_secret})
  end
end
