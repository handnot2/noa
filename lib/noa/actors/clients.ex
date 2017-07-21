defmodule Noa.Actors.Clients do
  @moduledoc false

  alias Ecto.{Changeset, Schema, UUID}
  alias Noa.{Repo, Actors.Client}

  @spec add(map) :: {:ok, Schema.t} | {:error, Changeset.t}
  def add(%{} = attrs) do
    %Client{} |> Client.create_cs(attrs) |> Repo.insert()
  end

  @spec lookup(binary) :: nil | Schema.t | {:error, binary}
  def lookup(id) when is_binary(id) do
    case UUID.cast(id) do
      {:ok, _} -> Repo.get(Client, id)
      _ -> {:error, "invalid_data"}
    end
  end

  @spec delete(Schema.t) :: {:ok, Schema.t} | {:error, Changeset.t}
  def delete(client) do
    Repo.delete(client)
  end
end
