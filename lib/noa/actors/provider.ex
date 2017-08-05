defmodule Noa.Actors.Provider do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.{Changeset}

  @default_access_token_ttl  15 * 60
  @default_refresh_token_ttl 30 * 60

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
    field :access_token_ttl, :integer, default: @default_access_token_ttl
    field :refresh_token_ttl, :integer, default: @default_refresh_token_ttl
    timestamps()
  end

  @req_attr_for_create []
  @optional_attr_for_create [:desc, :scope, :access_token_ttl, :refresh_token_ttl]

  def create_cs(provider, %{} = attrs) do
    provider
    |>  Changeset.cast(attrs, @req_attr_for_create ++ @optional_attr_for_create)
    |>  Changeset.validate_required(@req_attr_for_create)
    |>  Changeset.validate_number(:access_token_ttl, greater_than: 0)
    |>  Changeset.validate_number(:refresh_token_ttl, greater_than: 0)
    |>  additional_ttl_check()
    |>  gen_provider_id()
  end

  @req_attr_for_update []
  @optional_attr_for_update [:desc, :scope, :access_token_ttl, :refresh_token_ttl]

  def update_cs(provider, %{} = attrs) do
    provider
    |>  Changeset.cast(attrs, @req_attr_for_update ++ @optional_attr_for_update)
    |>  Changeset.validate_required(@req_attr_for_update)
    |>  Changeset.validate_number(:access_token_ttl, greater_than: 0)
    |>  Changeset.validate_number(:refresh_token_ttl, greater_than: 0)
    |>  additional_ttl_check()
  end

  defp additional_ttl_check(cs) do
    at_ttl = Changeset.get_field(cs, :access_token_ttl)
    rt_ttl = Changeset.get_field(cs, :refresh_token_ttl)
    if rt_ttl <= at_ttl do
      Changeset.add_error(cs, :refresh_token_ttl, "must be greater than access_token_ttl")
    else
      cs
    end
  end

  defp gen_provider_id(cs) do
    id = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    cs |> Changeset.put_change(:id, id)
  end
end
