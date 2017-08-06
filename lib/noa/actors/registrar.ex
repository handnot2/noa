defmodule Noa.Actors.Registrar do
  @moduledoc false

  alias Ecto.Changeset
  alias Noa.Tokens.{AC, AT, RT, ACGrant, RTGrant, CCGrant}
  alias Noa.{Repo, Tokens}

  @doc false
  @spec issue_authorization_code(map) ::
      {:ok, AC.t} | {:error, Changeset.t}
  def issue_authorization_code(%{} = claim) do
    %AC{} |> AC.create_cs(claim) |> Repo.insert()
  end

  @doc false
  @spec issue_access_token(AC.t | RT.t | map) :: {:ok, AT.t, nil | RT.t} | {:error, atom}
  def issue_access_token(%AC{} = code), do: ACGrant.issue_access_token(code)
  def issue_access_token(%RT{} = token), do: RTGrant.issue_access_token(token)
  def issue_access_token(%{client_id: _cid, provider_id: _provider_id, scope: _scope} = attrs) do
    CCGrant.issue_access_token(attrs)
  end

  @doc false
  def revoke(%AC{} = code),  do: Tokens.revoke(code)
  def revoke(%AT{} = token), do: Tokens.revoke(token)
  def revoke(%RT{} = token), do: Tokens.revoke(token)

  @doc false
  @spec lookup(binary, binary) :: nil | AC.t | AT.t | RT.t | {:error, :atom}
  def lookup(id, "authorization_code"), do: Tokens.lookup(AC, id)
  def lookup(id, "access_token"), do: Tokens.lookup(AT, id)
  def lookup(id, "refresh_token"), do: Tokens.lookup(RT, id)
  def lookup(_, _), do: {:error, :unsupported_token_type}
end
