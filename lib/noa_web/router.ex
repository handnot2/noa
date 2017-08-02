defmodule NoaWeb.Router do
  @moduledoc false

  use NoaWeb, :router
  alias NoaWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.DisableRespCache
  end

  pipeline :api do
    plug :accepts, ["urlencoded", "json"]
    plug Plugs.DisableRespCache
  end

  pipeline :authorize do
    plug Plugs.ProviderLoader
  end

  pipeline :issue do
    plug Plugs.ProviderLoader
    plug Plugs.ClientAuthenticator
    plug Plugs.EnsureAuthenticated, [:client]
  end

  pipeline :introspect do
    plug Plugs.ProviderLoader
    plug Plugs.ClientAuthenticator
    plug Plugs.ResourceAuthenticator
    plug Plugs.EnsureAuthenticated, [:client, :resource]
  end

  pipeline :consent do
    plug Plugs.ProviderLoader
    plug Plugs.AzTransitionCheck, stage: "consent", methods: ["GET"]
    plug Plugs.EnsureAuthenticated, [:resource_owner]
  end

  pipeline :idrp do
    plug Plugs.AzTransitionCheck, stage: "auth", methods: ["GET", "POST"]
    plug Ueberauth
  end

  pipeline :signin do
    plug Plugs.AzTransitionCheck, stage: "auth", methods: ["GET"]
  end

  scope "/as/v1/idp", NoaWeb do
    pipe_through [:browser, :signin]
    get  "/signin", SigninController, :show_signin
    post "/signin", SigninController, :signin
  end

  scope "/as/v1/idrp", NoaWeb do
    pipe_through [:browser, :idrp]
    get "/:provider", IdrpController, :request
    get "/:provider/callback", IdrpController, :callback
  end

  scope "/as/v1/:provider_id", NoaWeb do
    pipe_through [:browser, :consent]
    get  "/consent", ConsentController, :show_consent
    post "/consent", ConsentController, :consent
  end

  scope "/as/v1/:provider_id/authorize", NoaWeb do
    pipe_through [:api, :authorize]
    get "/", AuthorizeController, :authorize
  end

  scope "/as/v1/:provider_id/issue", NoaWeb do
    pipe_through [:api, :issue]
    post   "/", IssueController, :issue
  end

  scope "/as/v1/:provider_id/introspect", NoaWeb do
    pipe_through [:api, :introspect]
    post   "/", IntrospectController, :introspect
  end
end
