defmodule Noa.Tokens.AT do
  @moduledoc false

  use Noa.Tokens.Token

  @type t :: %__MODULE__{
    id: binary,
    provider_id: binary,
    issued_to: binary,
    authz_code_id: binary,
    refresh_token_id: binary,
    issued_on: DateTime.t,
    expires_on: DateTime.t,
    revoked_on: nil | DateTime.t,
    scope: binary
  }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "acc_tokens" do
    field :provider_id, :string
    field :issued_to, Ecto.UUID
    field :authz_code_id, Ecto.UUID
    field :refresh_token_id, Ecto.UUID
    field :issued_on, :utc_datetime
    field :expires_on, :utc_datetime
    field :revoked_on, :utc_datetime
    field :scope, :string

    timestamps()
  end

  @rt_create_attrs_required   [:provider_id, :issued_to,
                              :authz_code_id,
                              :refresh_token_id, :scope]
  @ac_create_attrs_required   [:provider_id, :issued_to,
                              :authz_code_id,
                              :refresh_token_id, :scope]
  @cc_create_attrs_required   [:provider_id, :issued_to,
                              :scope]

  def create_cs(token, %{} = attrs, %{grant_type: :refresh_token}) do
    create_cs_(token, attrs, @rt_create_attrs_required)
  end
  def create_cs(token, %{} = attrs, %{grant_type: :authorization_code}) do
    create_cs_(token, attrs, @ac_create_attrs_required)
  end
  def create_cs(token, %{} = attrs, %{grant_type: :client_credentials}) do
    create_cs_(token, attrs, @cc_create_attrs_required)
  end
end
