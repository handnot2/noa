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
          pipe_through :client_authenticator
          pipe_through :disable_resp_caching

          post   "/lookup", IntrospectController, :lookup
          post   "/issue",  IssueController, :issue
        end
      end
    end
  end
end
