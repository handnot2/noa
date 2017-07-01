defmodule Noa.Tokens.StubHandler do
  @type opts ::	binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @callback init(opts) :: opts | no_return
  @callback encode(binary, map, opts) :: {:ok, binary} | {:error, atom}
  @callback decode(binary, opts) :: {:ok, binary, map} | {:error, atom}

  def setup() do
    opts = Application.get_env(:noa, :stubhandler, [])
    handler = opts[:handler] || raise "missing/invalid :stubhandler config"
    handler_opts = handler.init(opts[:options])
    Application.put_env(:noa, :"_stubhandler", {handler, handler_opts})
  end

  def encode_stub(_token_type, id, claims \\ %{}) do
    {handler, handler_opts} = Application.get_env(:noa, :"_stubhandler")
    handler.encode(id, claims, handler_opts)
  end

  def decode_stub(_token_type, stub) do
    {handler, handler_opts} = Application.get_env(:noa, :"_stubhandler")
    handler.decode(stub, handler_opts)
  end
end
