defmodule Noa.Web do
  @moduledoc false

  def controller do
    quote do
      use Phoenix.Controller, namespace: Noa.Web
      import Plug.Conn
      import Noa.Web.Router.Helpers
      import Noa.Web.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/noa/web/templates",
                        namespace: Noa.Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import Noa.Web.Router.Helpers
      import Noa.Web.ErrorHelpers
      import Noa.Web.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import Noa.Web.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
