defmodule SilbernageldevWeb.ErrorHTMLTest do
  use SilbernageldevWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(SilbernageldevWeb.ErrorHTML, "404", "html", []) =~
             "I'm not sure what you're looking for"
  end

  test "renders 500.html" do
    assert render_to_string(SilbernageldevWeb.ErrorHTML, "500", "html", []) ==
             "Internal Server Error"
  end
end
