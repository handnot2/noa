defmodule Noa.Actors.Providers do
  @moduledoc false

  alias Ecto.{Changeset, Schema}
  alias Noa.{Repo, Actors.Provider}

  @spec add(map) :: {:ok, Schema.t} | {:error, Changeset.t}
  def add(%{} = attrs) do
    %Provider{} |> Provider.create_cs(attrs) |> Repo.insert()
  end

  @spec update(%Noa.Actors.Provider{}, map) :: {:ok, Schema.t} | {:error, Changeset.t}
  def update(%Noa.Actors.Provider{} = provider, %{} = attrs) do
    provider |> Provider.update_cs(attrs) |> Repo.update()
  end

  @spec lookup(binary) :: nil | Schema.t | {:error, atom}
  def lookup(id) when is_binary(id), do: Repo.get(Provider, id)

  @spec delete(Schema.t) :: {:ok, Schema.t} | {:error, Changeset.t}
  def delete(provider) do
    Repo.delete(provider)
  end
end
