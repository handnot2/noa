defmodule Noa.NoaHelper do
  import ExUnit.Assertions
  use Phoenix.ConnTest

  alias Noa.Actors.{Clients, Resources, Providers, Registrar}
  alias Noa.Tokens.{AC, StubHandler}

  def seed_test_context(initial_context \\ []) do
    ctxt = load_test_data_desc()
    |>  create_providers()
    |>  create_resources()
    |>  create_clients()

    initial_context
    |>  Keyword.merge(
          providers: ctxt[:providers],
          resources: ctxt[:resources],
          clients: ctxt[:clients])
  end

  def pr1(ctxt), do: get_in(ctxt, [:providers, "test_provider1"])
  def cl1(ctxt), do: get_in(ctxt, [:clients, "test_rs1client1"])
  def rs1(ctxt), do: get_in(ctxt, [:resources, "test_resource1"])

  def issue_code(pr, cl, res_owner) do
    claims = claims(pr, cl, res_owner)
    {:ok, %AC{} = code} = Registrar.issue_authorization_code(claims)
    code
  end

  def issue_tokens(pr, cl, res_owner) do
    code = claims(pr, cl, res_owner) |> authorization_code()
    {:ok, atoken, rtoken} = Registrar.issue_access_token(code)
    {atoken, rtoken}
  end

  def claims(provider, client, resource_owner, opts \\ []) do
    %{
      "provider_id"   => provider.id,
      "issued_to"     => client.id,
      "authorized_by" => resource_owner,
      "authorized_on" => DateTime.utc_now(),
      "redirect_uri"  => opts[:redirect_uri] || hd(client.uris),
      "scope"         => opts[:scope] || client.scope,
    }
  end

  def authorization_code(claims) do
    {:ok, %AC{} = code} = Registrar.issue_authorization_code(claims)
    assert code_ok?(code)
    code
  end

  def code_ok?(%AC{} = code) do
    assert code.id != nil
    assert code.issued_to != nil
    assert code.authorized_by != nil
    assert %DateTime{} = code.authorized_on
    assert %DateTime{} = code.issued_on
    assert %DateTime{} = code.expires_on
    assert code.redirect_uri != nil
    assert code.scope != nil
  end

  def get_token_stubs({atoken, rtoken}) do
    {get_stub(atoken, "access_token"), get_stub(rtoken, "refresh_token")}
  end

  def get_stub(nil, _token_type), do: nil
  def get_stub(token, token_type) when is_binary(token_type) do
    {:ok, stub} = StubHandler.encode_stub(token_type, token.id)
    stub
  end

  def relative_to_utc(n, :earlier), do: add_to_utc(-n)
  def relative_to_utc(n, :later), do: add_to_utc(n)

  def assert_token_error_resp(conn, status, error) do
    resp = json_response(conn, status)
    assert Map.get(resp, "error") == error
  end

  defp load_test_data_desc() do
    [data_desc] = YamlElixir.read_all_from_file("priv/repo/test_seed_data.yml")
    %{"data_desc" => data_desc}
  end

  defp create_providers(ctxt) do
    providers = get_in(ctxt, ["data_desc", "providers"])
    |>  Enum.map(fn attrs ->
          {:ok, prov} = Providers.add(attrs)
          {Map.get(attrs, "name"), prov}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :providers, providers)
  end

  defp create_resources(ctxt) do
    resources = get_in(ctxt, ["data_desc", "resources"])
    |>  Enum.map(fn attrs ->
          res_name = Map.get(attrs, "name")
          prov_name = Map.get(attrs, "provider")
          prov = get_in(ctxt, [:providers, prov_name])
          {:ok, res} = attrs
          |>  Map.put("secret", res_name)
          |>  Map.put("provider_id", prov.id)
          |>  Resources.add()
          {res_name, res}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :resources, resources)
  end

  defp create_clients(ctxt) do
    clients = get_in(ctxt, ["data_desc", "clients"])
    |>  Enum.map(fn attrs ->
          client_name = Map.get(attrs, "name")
          {:ok, client} = attrs
          |>  Map.put("secret", client_name)
          |>  Clients.add()
          {client_name, client}
        end)
    |>  Enum.into(%{})
    Map.put(ctxt, :clients, clients)
  end

  defp add_to_utc(n) do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> Kernel.+(n)
    |> DateTime.from_unix!()
  end
end
