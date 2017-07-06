defmodule Noa.Web.Router do
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

  scope "/as", Noa.Web do
    scope "/:provider_id" do
      pipe_through :provider_loader

      scope "/v1" do
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
      end
    end
  end
end
