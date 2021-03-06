# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :noa,
  ecto_repos: [Noa.Repo]

# Configures the endpoint
config :noa, NoaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hv9rzU8jgunIUg/6Pgmg9JMWy7TVn8MmhdJq84QZHysijgVUxNzNKRAiy+jVQS9i",
  render_errors: [view: NoaWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Noa.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ueberauth, Ueberauth,
  base_path: "/as/v1/idrp",
  providers: [
    noa: {NoaWeb.NoaStrategy, []},
  ]

config :mime, :types, %{
  "application/x-www-form-urlencoded" => ["urlencoded"]
}

config :mix_docker, image: "noa"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
