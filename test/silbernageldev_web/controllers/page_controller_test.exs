defmodule SilbernageldevWeb.PageControllerTest do
  use SilbernageldevWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Matt Silbernagel"
  end
end
