defmodule SilbernageldevGem do
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def controller do
    quote do
      use Orbit.Controller

      import Orbit.Controller
      import Orbit.Request
      import Orbit.Status
    end
  end

  def view do
    quote do
      import Orbit.Gemtext, only: [sigil_G: 2]
      import Orbit.View
    end
  end
end
