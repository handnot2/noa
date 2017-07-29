defmodule Noa.Web.Router do
  @moduledoc false

  use Noa.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :provider_loader do
    plug Noa.Web.Plugs.ProviderLoader
  end

  pipeline :client_authenticator do
    plug Noa.Web.Plugs.ClientAuthenticator
    plug Noa.Web.Plugs.EnsureAuthenticated, [:client]
  end

  pipeline :introspect_authenticator do
    plug Noa.Web.Plugs.ResourceAuthenticator
    plug Noa.Web.Plugs.EnsureAuthenticated, [:resource, :client]
  end

  pipeline :disable_resp_caching do
    plug Noa.Web.Plugs.DisableRespCache
  end

  pipeline :ueberauth do
    plug Ueberauth
  end

  pipeline :idrp_guard do
    plug Noa.Web.Plugs.IdrpGuard
  end

  pipeline :ro_auth_guard do
    plug Noa.Web.Plugs.ROAuthGuard
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/idrp", Noa.Web.Idrp do
    pipe_through [:browser, :idrp_guard, :ueberauth]

    get "/:provider", IdrpController, :request
    get "/:provider/callback", IdrpController, :callback
  end

  scope "/idp", Noa.Web do
    pipe_through [:browser, :disable_resp_caching]

    get  "/signin", SigninController, :show_signin
    post "/signin", SigninController, :signin
  end

  scope "/as", Noa.Web do
    scope "/v1" do
      scope "/:provider_id" do
        pipe_through :provider_loader

        scope "/tokens" do
          pipe_through :api
          pipe_through :disable_resp_caching

          scope "/lookup" do
            pipe_through :introspect_authenticator
            post   "/", IntrospectController, :introspect
          end

          scope "/issue" do
            pipe_through :client_authenticator
            post   "/",  IssueController, :issue
          end
        end

        scope "/authorize", Authorize do
          pipe_through [:api, :disable_resp_caching]

          get "/", AzController, :authorize
        end

        scope "/consent" do
          pipe_through [:browser, :disable_resp_caching, :ro_auth_guard]

          get  "/", ConsentController, :show_consent
          post "/", ConsentController, :consent
        end
      end
    end

    scope "/", Noa.Web do
      pipe_through [:browser, :disable_resp_caching]
      get  "/", PageController, :index
    end
  end
end
