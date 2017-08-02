defmodule NoaWeb.FallbackController do
  @moduledoc false

  use NoaWeb, :controller

  @error_to_http_status %{
    invalid_request: 400,
    invalid_scope: 400,
    invalid_grant: 400,
    unsupported_grant_type: 400,
    unsupported_response_type: 400,
    store_failure: 500,
    server_error: 500,
    temporarily_unavailable: 503,
  }

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(NoaWeb.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, ec}) when is_atom(ec) do
    conn
    |> put_status(Map.get(@error_to_http_status, ec, 400))
    |> json(%{error: ec})
  end

  def call(conn, {:error, ec, desc}) when is_atom(ec) and is_binary(desc) do
    conn
    |> put_status(Map.get(@error_to_http_status, ec, 400))
    |> json(%{error: ec, error_description: desc})
  end
end
