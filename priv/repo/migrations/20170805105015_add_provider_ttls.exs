defmodule Noa.Repo.Migrations.AddProviderTTLs do
  use Ecto.Migration

  def change do
    alter table(:providers) do
      add :access_token_ttl,  :integer
      add :refresh_token_ttl, :integer
    end
  end
end
