defmodule Noa.Tokens.OpaqueStubHandler do
  @moduledoc false

  @behaviour Noa.Tokens.StubHandler
  alias Plug.Crypto.MessageVerifier

  def init(opts), do: %{secret: secret(opts)}

  def encode(id, %{} = _claims, %{secret: secret}) when is_binary(id) do
    {:ok, MessageVerifier.sign(id, secret, :sha256)}
  end

  def decode(stub, %{secret: secret}) when is_binary(stub) do
    with {:ok, id} <- MessageVerifier.verify(stub, secret)
    do
      {:ok, id, %{}}
    end
  end

  defp secret([secret: secret]) when is_binary(secret) and byte_size(secret) >= 32, do: secret
  defp secret(_), do: raise "Missing/Invalid OpaqueStubHandler secret"
end
