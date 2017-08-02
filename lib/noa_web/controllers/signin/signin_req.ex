defmodule NoaWeb.SigninReq do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset, as: CS
  alias NoaWeb.{SigninReq}

  embedded_schema do
    field :username
    field :pswd
    field :user_info
    field :target_url
    field :state
  end

  @show_signin_required_fields [:target_url, :state]
  @show_signin_optional_fields [:username]

  def show_signin_cs(%{} = params, expected_state) do
    %SigninReq{}
    |> cast(params, @show_signin_required_fields ++ @show_signin_optional_fields)
    |> validate_required(@show_signin_required_fields, message: "missing")
    |>  validate_change(:state, fn :state, state ->
          if state == expected_state, do: [], else: [state: "mismatch"]
        end)
  end

  @signin_fields [:username, :pswd, :target_url, :state]
  @signin_required_fields @signin_fields

  def signin_cs(%{} = params) do
    %SigninReq{}
    |> cast(params, @signin_fields)
    |> validate_required(@signin_required_fields, message: "missing")
    |> validate_creds()
  end

  defp validate_creds(%CS{valid?: false} = cs), do: cs
  defp validate_creds(%CS{} = cs) do
    user_adapter = get_user_adapter()
    username = get_change(cs, :username)
    pswd     = get_change(cs, :pswd)
    case apply(user_adapter, :get_by_creds, [username, pswd]) do
      {:ok, user_info} ->
        cs |> put_change(:user_info, user_info)
      {:error, :invalid_creds} ->
        cs |> add_error(:username, "signin failed")
      {:error, :locked} ->
        cs |> add_error(:username, "locked")
    end
  end

  defp get_user_adapter(), do: SigninReq

  def get_by_creds(username, pswd) do
    if username == "aloha@mahalo.net" && pswd == "mahalo" do
      {:ok, %{"username" => username}}
    else
      {:error, :invalid_creds}
    end
  end
end
