defmodule SilbernageldevGem.GemCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @router SilbernageldevGem.Router

      import OrbitTest
    end
  end
end
