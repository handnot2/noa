defmodule Noa.Tokens.Token do
  @moduledoc false

  defmacro __using__(_) do
    quote location: :keep do
      use Ecto.Schema
      import Ecto.Changeset

      defp create_cs_(token, %{} = attrs, required_attrs, optional_attrs \\ []) do
        token
        |> cast(attrs, required_attrs ++ optional_attrs)
        |> validate_required(required_attrs)
        |> handle_expiration(attrs)
      end

      defp handle_expiration(cs, attrs) do
        cs
        |> cast(attrs, [:issued_on, :expires_on])
        |> add_issued_on(attrs)
        |> add_expires_on(attrs)
      end

      defp add_issued_on(cs, _attrs), do: cs |> put_change(:issued_on, DateTime.utc_now())

      defp add_expires_on(cs, %{} = attrs) do
        issued_on_unix = cs |> get_change(:issued_on) |> DateTime.to_unix()
        expires_in = Map.get(attrs, "expires_in") || Map.get(attrs, :expires_in) || 5 * 60
        expires_on_utc = DateTime.from_unix!(issued_on_unix + expires_in)
        cs |> put_change(:expires_on, expires_on_utc)
      end
    end
  end
end
