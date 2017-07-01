defmodule Noa.Actors.Provider do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.{Changeset}

  @primary_key {:id, :string, autogenerate: false}
  schema "providers" do
    field :desc, :string, default: ""
    field :scope, :string, default: ""
    field :endpoint_auth, :string, default: "form_post"
    field :signing_alg, :string, default: ""
    field :resonse_types, {:array, :string}, default: []
    field :response_modes, {:array, :string}, default: []
    field :claims, {:array, :string}, default: []
    field :grant_types, {:array, :string}, default: []
    timestamps()
  end

  def create_cs(provider, %{} = attrs) do
    provider
    |> Changeset.cast(attrs, [:desc, :scope])
    |> gen_provider_id()
  end

  def update_cs(provider, %{} = attrs) do
    provider
    |> Changeset.cast(attrs, [:desc, :scope])
  end

  defp gen_provider_id(cs) do
    id = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    cs |> Changeset.put_change(:id, id)
  end
end
