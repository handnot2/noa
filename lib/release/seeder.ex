defmodule NoaRelease.Seeder do
  alias Noa.Actors.{Clients, Resources, Providers}

  def seed(data_file) do
    IO.inspect(data_file, label: "Seeding from")
    ctxt = load_data_desc(data_file)
    |>  create_providers()
    |>  create_resources()
    |>  create_clients()

    %{
      providers: ctxt[:providers],
      resources: ctxt[:resources],
      clients:   ctxt[:clients]
    }
  end

  def print_seed_data_ids(%{} = seed_result) do
    %{providers: prs, resources: rss, clients: cls} = seed_result
    host = System.get_env("NOA_HOST") || "localhost"
    port = System.get_env("NOA_PORT") || "4000"

    IO.puts("\n========= 8< =========\n")
    IO.puts("Use the information shown here when working with Noa Playground.")
    IO.puts("\nProviders:")
    prs
    |>  Enum.each(fn {n, v} ->
          IO.puts("\n#{n}: #{inspect v.id}")
          IO.puts("  Provider URL: http://#{host}:#{port}/as/v1/#{v.id}")
        end)
    IO.puts("\nClients:\n")
    cls
    |>  Enum.each(fn {n, v} ->
          IO.puts("#{n} OAuth Client ID: #{inspect v.id}")
        end)
    IO.puts("\nResources:\n")
    rss |> Enum.each(fn {n, v} -> IO.puts("#{n} ID: #{inspect v.id}") end)
    IO.puts("\n========= 8< =========\n")
  end

  defp load_data_desc(file) do
    [data_desc] = YamlElixir.read_all_from_file(file)
    %{"data_desc" => data_desc}
  end

  defp create_providers(ctxt) do
    providers = get_in(ctxt, ["data_desc", "providers"])
    |>  Enum.map(fn attrs ->
          {:ok, prov} = Providers.add(attrs)
          {Map.get(attrs, "name"), prov}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :providers, providers)
  end

  defp create_resources(ctxt) do
    resources = get_in(ctxt, ["data_desc", "resources"])
    |>  Enum.map(fn attrs ->
          res_name = Map.get(attrs, "name")
          prov_name = Map.get(attrs, "provider")
          prov = get_in(ctxt, [:providers, prov_name])
          {:ok, res} = attrs
          |>  Map.put_new("secret", res_name)
          |>  Map.put("provider_id", prov.id)
          |>  Resources.add()
          {res_name, res}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :resources, resources)
  end

  defp create_clients(ctxt) do
    clients = get_in(ctxt, ["data_desc", "clients"])
    |>  Enum.map(fn attrs ->
          client_name = Map.get(attrs, "name")
          {:ok, client} = attrs
          |>  Map.put_new("secret", client_name)
          |>  Clients.add()
          {client_name, client}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :clients, clients)
  end
end
