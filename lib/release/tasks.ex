defmodule NoaRelease.Tasks do
  alias Ecto.Migrator
  alias Noa.Repo

  def migrate() do
    load_app()
    if migration_pending?() do
      Migrator.run(Repo, migration_path(), :up, all: true)
    end
    unload_app()
  end

  def seed(), do: seed([])
  def seed(params) do
    IO.puts("Seed params: #{inspect params}")
    load_app()
    demo_seed_data_path()
    |>  NoaRelease.Seeder.seed()
    |>  NoaRelease.Seeder.print_seed_data_ids()
    unload_app()
  end

  defp migration_pending?() do
    shipped_migrations = Migrator.migrations(Repo, migration_path())
    migrated_versions  = Migrator.migrated_versions(Repo)
    all_migrated? = shipped_migrations
    |>  Enum.all?(fn {_, version, _} -> version in migrated_versions end)
    !all_migrated?
  end

  defp migration_path() do
    Path.join([:code.priv_dir(:noa), "repo", "migrations"])
  end

  defp demo_seed_data_path() do
    System.get_env("NOA_SEED_DATA_FILE")
  end

  defp load_app() do
    IO.puts("Loading noa ...")
    :ok = Application.load(:noa)

    IO.puts("Starting dependencies ...")
    [:crypto, :ssl, :postgrex, :ecto, :yamerl]
    |>  Enum.each(&Application.ensure_all_started/1)

    IO.puts("Starting Repo ...")
    [Noa.Repo]
    |>  Enum.each(&(&1.start_link(pool_size: 1)))
  end

  defp unload_app() do
    IO.puts("Unloading noa ...")
    :init.stop()
  end
end
