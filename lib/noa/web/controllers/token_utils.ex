defmodule Noa.Web.TokenUtils do
  alias Noa.Tokens
  alias Noa.Tokens.{AC, AT, RT, StubHandler}

  @doc false
  @spec get_validated_token(binary, binary) :: {:ok, Tokens.token_t} | {:error, atom}
  def get_validated_token(stub, "authorization_code" = tt), do: get_token_by_stub(AC, tt, stub)
  def get_validated_token(stub, "access_token" = tt), do: get_token_by_stub(AT, tt, stub)
  def get_validated_token(stub, "refresh_token" = tt), do: get_token_by_stub(RT, tt, stub)

  @doc false
  def check_validity_period(token), do: cvp_result(Tokens.validity_period_status(token))

  @doc false
  def check_revocation_status(token), do: crs_result(Tokens.revoked?(token))

  defp get_token_by_stub(token_module, token_type, stub) do
    with  {:ok, id, _} <- StubHandler.decode_stub(token_type, stub),
          token when token != nil <- Tokens.lookup(token_module, id)
    do
      {:ok, token}
    else
      _ -> {:error, :invalid_grant}
    end
  end

  defp cvp_result(:in), do: :ok
  defp cvp_result(:before), do: {:error, :used_before_validity}
  defp cvp_result(:after), do: {:error, :used_after_validity}

  defp crs_result(false), do: :ok
  defp crs_result(true), do: {:error, :revoked}
end
