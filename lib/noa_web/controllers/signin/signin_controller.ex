defmodule NoaWeb.SigninController do
  @moduledoc false

  use NoaWeb, :controller

  import Ecto.Changeset
  alias NoaWeb.{SigninReq}

  def show_signin(conn, %{} = params) do
    # make sure that there is already a session with OAuth2 authroize request information
    cs = SigninReq.show_signin_cs(params, get_session(conn, "x-noa-az-state-auth"))
    if cs.valid? do
      reqdata = get_session(conn, "x-noa-authz-req-data") || %{}
      client  = Map.get(reqdata, :client)
      signin_path = NoaWeb.Router.Helpers.signin_path(NoaWeb.Endpoint, :signin)
      conn
      |>  put_resp_header("x-csrf-token", get_csrf_token())
      |>  put_status(200)
      |>  render("signin.html", [params: params, client_name: client.name, signin_path: signin_path])
    else
      conn
      |>  put_status(403)
      |>  json(%{error: :forbidden, tag: "nsc-1"})
    end
  end

  def signin(conn, %{} = params) do
    cs = SigninReq.signin_cs(params)
    cond do
      cs.valid? ->
        signedin_user = cs |> get_change(:user_info)
        target_url  = cs |> get_change(:target_url)
        state       = cs |> get_change(:state)
        redirect_to = target_url <> "?state=#{state}"
        conn
        |>  put_session("x-noa-signedin-user", signedin_user)
        |>  redirect(external: redirect_to)
      true ->
        reqdata = get_session(conn, "x-noa-authz-req-data") || %{}
        client  = Map.get(reqdata, :client)
        signin_path = NoaWeb.Router.Helpers.signin_path(NoaWeb.Endpoint, :signin)
        assigns = [params: params, error_msg: "Signin failed",
          client_name: client.name, signin_path: signin_path]
        conn
        |>  put_status(200)
        |>  render("signin.html", assigns)
    end
  end
end
