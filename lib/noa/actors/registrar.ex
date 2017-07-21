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
  def revoke_authorization_code(%AC{} = code), do: Tokens.revoke(code)

  @doc false
  def revoke_access_token(%AT{} = token), do: Tokens.revoke(token)

  @doc false
  def revoke_refresh_token(%RT{} = token), do: Tokens.revoke(token)
end
