defmodule Noa.Actors.Resources do
  @moduledoc false

  import Ecto.Query, only: [from: 2]
  alias Ecto.{Changeset, Schema, UUID}
  alias Noa.{Repo, Actors.Resource}

  @spec add(map) :: {:ok, Schema.t} | {:error, Changeset.t}
  def add(%{} = attrs) do
    %Resource{} |> Resource.create_cs(attrs) |> Repo.insert()
  end

  @spec lookup(binary) :: nil | Schema.t | {:error, binary}
  def lookup(id) when is_binary(id) do
    case UUID.cast(id) do
      {:ok, _} -> Repo.get(Resource, id)
      _ -> {:error, "invalid_data"}
    end
  end

  @spec get_by_provider(binary) :: [Schema.t] | {:error, atom}
  def get_by_provider(provider_id) when is_binary(provider_id) do
    Repo.all(from r in Resource, where: r.provider_id == ^provider_id)
  end

  @spec delete(Schema.t) :: {:ok, Schema.t} | {:error, Changeset.t}
  def delete(res) do
    Repo.delete(res)
  end
end
