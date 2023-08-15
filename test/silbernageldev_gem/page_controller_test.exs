defmodule SilbernageldevGem.PageControllerTest do
  use SilbernageldevGem.GemCase

  describe "PageController.home/2" do
    test "says hello to the world with no client certificate" do
      req = request("/")

      assert body(req) =~ "ahappydeath"
    end
  end
end
