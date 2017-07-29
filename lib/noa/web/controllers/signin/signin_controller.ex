defmodule Noa.Web.SigninController do
  use Noa.Web, :controller

  import Ecto.Changeset
  alias Noa.Web.{SigninReq}

  def show_signin(conn, %{} = params) do
    # make sure that there is already a session with OAuth2 authroize request information
    cs = SigninReq.show_signin_cs(params)
    if cs.valid? do
      conn
      |>  put_resp_header("x-csrf-token", get_csrf_token())
      |>  put_status(200)
      |>  render("signin.html", params: params)
    else
      IO.inspect(cs, label: "show_signin")
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
        conn
        |>  put_status(200)
        |>  render("signin.html", params: params, error_msg: "Signin failed")
    end
  end
end
