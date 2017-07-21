defmodule Noa.Tokens.Scopes do
  @moduledoc false

  alias Noa.Actors.{Resource, Resources, Provider}

  def get(%Resource{} = resource), do: get(resource, MapSet.new())
  def get(resources) when is_list(resources), do: get(resources, MapSet.new())

  def get(%Provider{} = provider) do
    provider.scope |> String.split() |> MapSet.new()
  end

  def get(%Resource{} = resource, merge_with) do
    resource.scope |> String.split() |> MapSet.new() |> MapSet.union(merge_with)
  end

  def get(resources, merge_with) when is_list(resources) do
    resources |> Enum.reduce(merge_with, fn r, acc -> MapSet.union(acc, get(r)) end)
  end

  def get(%Provider{} = provider, resources) when is_list(resources) do
    get(resources, get(provider))
  end

  def get_all(%Provider{} = provider) do
    get(Resources.get_by_provider(provider.id), get(provider))
  end
end
