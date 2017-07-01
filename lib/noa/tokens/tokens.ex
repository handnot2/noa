defmodule Noa.Tokens do
  @moduledoc false

  import Ecto.Changeset
  alias  Ecto.{Adapters.SQL, Changeset, Schema, UUID}
  alias  Noa.{Repo}
  alias  Noa.Tokens.{AC, AT, RT}

  @type token_t :: AC.t | AT.t | RT.t
  @type token_module_t :: AC | AT | RT
  @type validity_period_status_t :: :before | :in | :after

  @reap_chunk_size 50

  @spec lookup(token_module_t, binary) :: nil | Schema.t | {:error, atom}
  def lookup(module, id) when module in [AC, AT, RT] do
    case UUID.cast(id) do
      {:ok, _} -> Repo.get(module, id)
      _ -> {:error, :invalid_data}
    end
  end

  @spec revoke(Schema.t) :: {:ok, Schema.t} | {:error, Changeset.t}
  def revoke(token) do
    token
    |>  cast(%{"revoked_on" => DateTime.utc_now()}, [:revoked_on])
    |>  Repo.update()
  end

  @spec delete(Schema.t) :: {:ok, Schema.t} | {:error, Changeset.t}
  def delete(token), do: Repo.delete(token)

  @spec reap(token_module_t, Keyword.t) :: {:ok, integer} | {:error, Exception.t}
  def reap(module, opts) when module in [AC, AT, RT] and is_list(opts) do
    exp = opts |> Keyword.get(:expired_on_or_before, DateTime.utc_now())
    limit = opts |> Keyword.get(:limit, @reap_chunk_size)
    q = "SELECT * FROM reap_#{module.__schema__(:source)}($1, $2)"
    case Repo |> SQL.query(q, [exp, limit]) do
      {:ok, %{num_rows: num_rows}} -> {:ok, num_rows}
      error -> error
    end
  end

  @spec expires_in(token_t) :: non_neg_integer
  def expires_in(token) do
    DateTime.to_unix(Map.get(token, :expires_on)) - DateTime.to_unix(Map.get(token, :issued_on))
  end

  @spec validity_period_status(token_t) :: validity_period_status_t
  def validity_period_status(token) do
    current_time = DateTime.utc_now()
    cond do
      DateTime.compare(current_time, Map.get(token, :issued_on)) == :lt  -> :before
      DateTime.compare(current_time, Map.get(token, :expires_on)) == :gt -> :after
      true -> :in
    end
  end

  @spec revoked?(token_t) :: boolean
  def revoked?(%{revoked_on: nil}), do: false
  def revoked?(%{revoked_on: _}), do: true
end
