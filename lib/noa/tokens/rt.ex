defmodule Noa.Tokens.RT do
  @moduledoc false

  use Noa.Tokens.Token

  @type t :: %__MODULE__{
    id: binary,
    provider_id: binary,
    issued_to: binary,
    authz_code_id: binary,
    parent_token_id: binary,
    issued_on: DateTime.t,
    expires_on: DateTime.t,
    revoked_on: nil | DateTime.t,
    scope: binary
  }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "ref_tokens" do
    field :provider_id, :string
    field :issued_to, Ecto.UUID
    field :authz_code_id, Ecto.UUID
    field :parent_token_id, Ecto.UUID
    field :issued_on, :utc_datetime
    field :expires_on, :utc_datetime
    field :revoked_on, :utc_datetime
    field :scope, :string

    timestamps()
  end

  @create_attrs_required [:provider_id, :issued_to, :authz_code_id, :scope]
  def create_cs(token, %{} = attrs) do
    create_cs_(token, attrs, @create_attrs_required)
  end
end
