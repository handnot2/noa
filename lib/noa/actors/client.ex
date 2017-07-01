defmodule Noa.Actors.Client do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.{Changeset, UUID}

  @primary_key {:id, UUID, autogenerate: true}
  schema "clients" do
    field :name, :string
    field :secret_hash, :string
    field :enc_token_secret, :string
    field :scope, :string, default: ""
    field :uris, {:array, :string}, default: []
    timestamps()
  end

  def create_cs(client, %{} = attrs) do
    client
    |> Changeset.cast(attrs, [:name, :scope, :uris])
    |> Changeset.validate_required([:name, :uris], message: "missing")
    |> Changeset.validate_length(:name, min: 5, max: 125)
    |> Changeset.unique_constraint(:name, name: :clients_name_idx)
    |> Changeset.validate_change(:uris, &validate_uris/2)
    |> validate_secret(Map.get(attrs, "secret"), required: true)
  end

  def update_cs(client, %{} = attrs) do
    client
    |> Changeset.cast(attrs, [:id, :name, :scope, :uris])
    |> Changeset.validate_required([:id], message: "missing")
    |> Changeset.validate_length(:name, min: 5, max: 125)
    |> Changeset.validate_change(:uris, &validate_uris/2)
    |> validate_secret(Map.get(attrs, "secret"), required: false)
  end

  def update_token_secret_cs(res, secret) do
    #TODO: attrs = %{"enc_token_secret" => Vault.encrypt("clients", secret)}
    attrs = %{"enc_token_secret" => secret}
    res |> Changeset.cast(attrs, [:enc_token_secret])
  end

  defp validate_uris(:uris, uris) do
    if uris |> Enum.any?(fn u -> valid_redirect_uri?(u) == false end) do
      [uris: "invalid_data"]
    else
      []
    end
  end

  defp valid_redirect_uri?(uri) do
    %URI{fragment: f, host: h, path: p, query: q, scheme: s, userinfo: u} = URI.parse(uri)
    f == nil && h != nil && p != nil && q == nil && s in ~w(http https) && u == nil
  end

  defp validate_secret(cs, nil, required: false), do: cs
  defp validate_secret(cs, nil, required: true), do: Changeset.add_error(cs, :secret, "missing")
  defp validate_secret(cs, secret, _) do
    cond do
      String.length(secret) < 5 -> Changeset.add_error(cs, :secret, "minimum size 5")
      cs.valid? == false -> cs
      true ->
        secret_hash = Comeonin.Bcrypt.hashpwsalt(secret)
        cs |> Changeset.put_change(:secret_hash, secret_hash)
    end
  end
end
