defmodule SilbernageldevGem.LayoutView do
  use SilbernageldevGem, :view

  def base_url() do
    "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
  end

  embed_templates "layout_view/*"
end
