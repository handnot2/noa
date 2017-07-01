defmodule Noa.Repo.Migrations.CreateNoaBase do
  use Ecto.Migration

  def change do
    create table(:providers, primary_key: false) do
      add :id, :string, primary_key: true
      add :status, :integer
      add :desc, :string
      add :scope, :text
      add :endpoint_auth, :string
      add :signing_alg, :string
      add :resonse_types, {:array, :string}
      add :response_modes, {:array, :string}
      add :claims, {:array, :string}
      add :grant_types, {:array, :string}

      timestamps()
    end

    create table(:clients, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :secret_hash, :string
      add :enc_token_secret, :text
      add :scope, :text
      add :uris, {:array, :text}

      timestamps()
    end

    create index(:clients, [:name], name: :clients_name_idx, unique: true)

    create table(:resources, primary_key: false) do
     add :id, :uuid, primary_key: true
     add :name, :string
     add :scope, :text
     add :owner_id, :uuid
     add :enc_token_secret, :text

     timestamps()
    end

    create index(:resources, [:name], name: :resources_name_idx)

    create table(:authz_codes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :provider_id, :string
      add :issued_to, :uuid
      add :authorized_by, :text
      add :authorized_on, :utc_datetime
      add :issued_on, :utc_datetime
      add :expires_on, :utc_datetime
      add :exchanged_on, :utc_datetime
      add :revoked_on, :utc_datetime
      add :redirect_uri, :text
      add :scope, :text

      timestamps()
    end

    create index(:authz_codes, [:expires_on], name: :authz_codes_expires_on_idx)

    create table(:acc_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :provider_id, :string
      add :issued_to, :uuid
      add :authz_code_id, :uuid
      add :refresh_token_id, :uuid
      add :issued_on, :utc_datetime
      add :expires_on, :utc_datetime
      add :exchanged_on, :utc_datetime
      add :revoked_on, :utc_datetime
      add :scope, :text

      timestamps()
    end

    create index(:acc_tokens, [:expires_on], name: :acc_tokens_expires_on_idx)

    create table(:ref_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :provider_id, :string
      add :issued_to, :uuid
      add :authz_code_id, :uuid
      add :parent_token_id, :uuid
      add :issued_on, :utc_datetime
      add :expires_on, :utc_datetime
      add :exchanged_on, :utc_datetime
      add :revoked_on, :utc_datetime
      add :scope, :text

      timestamps()
    end

    create index(:ref_tokens, [:expires_on], name: :ref_tokens_expires_on_idx)
  end
end
