defmodule Noa.Application do
  @moduledoc false

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    Noa.Tokens.StubHandler.setup()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Noa.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Noa.Web.Endpoint, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Noa.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
