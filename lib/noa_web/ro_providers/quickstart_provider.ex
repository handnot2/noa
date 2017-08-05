defmodule Noa.ROProviders.QuickstartProvider do
  @moduledoc false

  @behaviour Noa.ROProvider
  use GenServer

  require Logger

  @creds_table :noa_ro_creds

  def get_by_creds(username, passwd) do
    case :ets.lookup(@creds_table, username) do
      [{^username, ^passwd}] -> {:ok, %{"username" => username}}
      _ -> {:error, :invalid_creds}
    end
  end

  def start_link(gs_opts \\ []) do
    GenServer.start_link(__MODULE__, [], gs_opts)
  end

  def init([]) do
    opts = Application.get_env(:noa, :resource_owners, [])
    creds_file = opts[:options][:creds_file]

    send(self(), :load)
    state = %{creds_file: creds_file}
    {:ok, state}
  end

  def handle_info(:load, state) do
    creds_file = Map.get(state, :creds_file)
    load_creds(creds_file)
    {:noreply, state}
  end

  defp load_creds(nil), do: load_creds("ro_quickstart.creds")
  defp load_creds(file) when is_binary(file) do
    if :ets.info(@creds_table) != :undefined do
      :ets.delete(@creds_table)
    end

    :ets.new(@creds_table, [:set, :protected, :named_table])
    try do
      file
      |> File.stream!()
      |> Stream.filter(&(Regex.match?(~r/.+:.+/, &1)))
      |> Stream.map(&(String.trim_trailing(&1, "\n")))
      |> Stream.map(fn l ->
           [id, se] = l |> String.split(":", parts: 2)
           {String.trim(id), String.trim(se)}
         end)
      |> Enum.map(fn {id, se} -> :ets.insert(@creds_table, {id, se}) end)
    rescue
      e -> Logger.log(:error, "ERROR reading #{file}: #{inspect e}")
    end
  end
end
