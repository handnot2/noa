use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :noa, NoaWeb.Endpoint,
  http: [port: 4000],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :noa, Noa.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "db",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :noa, :stubhandler,
  handler: Noa.Tokens.OpaqueStubHandler,
  options: [secret: "1es_oeh9RboWFSySBZ02oA0DdfeVouYp7i0mVnn8Y0E"]

config :comeonin,
  bcrypt_log_rounds: 10,
  pbkdf2_rounds: 100_000
