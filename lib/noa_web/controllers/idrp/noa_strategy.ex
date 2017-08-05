defmodule NoaWeb.NoaStrategy do
  @moduledoc false

  use Ueberauth.Strategy, uid_field: :username

  alias Plug.Conn
  alias Ueberauth.Auth.{Info, Credentials, Extra}
  import NoaWeb.Router.Helpers, only: [signin_path: 2, idrp_path: 3]

  def handle_request!(%Conn{} = conn) do
    idrp_state = conn.params["state"]
    authz_req_data = Conn.get_session(conn, "x-noa-authz-req-data")
    if authz_req_data do
      signin_path = signin_path(NoaWeb.Endpoint, :show_signin)
      target_path = idrp_path(NoaWeb.Endpoint, :callback, "noa")
      redirect_to = signin_path <> "?state=#{idrp_state}&target_url=#{target_path}"
      conn
      |>  redirect!(URI.encode(redirect_to))
    else
      conn
      |>  Conn.delete_session("x-noa-az-state-auth")
      |>  set_errors!([error("uebnoa-1", "data missing")])
    end
  end

  def handle_callback!(%Conn{} = conn) do
    signedin_user = Conn.get_session(conn, "x-noa-signedin-user")
    if signedin_user do
      conn |> Conn.put_private(:signedin_user, signedin_user)
    else
      conn |> set_errors!([error("uebnoa-3", "signin_failed")])
    end
  end

  def handle_cleanup!(conn) do
    conn
    |>  Conn.delete_session("x-noa-signedin-user")
  end

  def uid(conn) do
    user_data = conn.private[:signedin_user]
    user_data["username"]
  end

  def credentials(_conn) do
    %Credentials{
      expires: false,
    }
  end

  def info(conn) do
    user_data = conn.private[:signedin_user]
    %Info{
      name: user_data["username"],
      email: user_data["username"],
    }
  end

  def extra(conn) do
    %Extra {
      raw_info: %{
        user: conn.private[:signedin_user]
      }
    }
  end
end
