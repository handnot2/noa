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

  def seed() do
    plain_args = :init.get_plain_arguments()
    pwd = System.get_env("PWD")

    load_app()
    plain_args
    |>  Enum.map(fn file -> Path.absname(file, pwd) end)
    |>  Enum.map(&NoaRelease.Seeder.seed/1)
    |>  Enum.map(&NoaRelease.Seeder.print_seed_data_ids/1)
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
