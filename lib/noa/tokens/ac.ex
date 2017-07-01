defmodule Noa.Tokens.AC do
  @moduledoc false

  use Noa.Tokens.Token

  @type t :: %__MODULE__{
    id: binary,
    provider_id: binary,
    issued_to: binary,
    authorized_by: binary,
    authorized_on: DateTime.t,
    issued_on: DateTime.t,
    expires_on: DateTime.t,
    exchanged_on: nil | DateTime.t,
    revoked_on: nil | DateTime.t,
    redirect_uri: binary,
    scope: binary
  }

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "authz_codes" do
    field :provider_id, :string
    field :issued_to, Ecto.UUID
    field :authorized_by, :string
    field :authorized_on, :utc_datetime
    field :issued_on, :utc_datetime
    field :expires_on, :utc_datetime
    field :exchanged_on, :utc_datetime
    field :revoked_on, :utc_datetime
    field :redirect_uri, :string
    field :scope, :string

    timestamps()
  end

  @create_attrs_required [:provider_id, :issued_to,
                          :authorized_by, :authorized_on,
                          :redirect_uri, :scope]

  def create_cs(ac, %{} = attrs) do
    create_cs_(ac, attrs, @create_attrs_required)
  end
end
