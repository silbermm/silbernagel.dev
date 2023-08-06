defmodule SilbernageldevGem.PageControllerTest do
  use SilbernageldevGem.GemCase

  describe "PageController.home/2" do
    test "says hello to the world with no client certificate" do
      req = request("/")

      assert body(req) =~ "Hello, world!"
    end

    test "says hello to the user with a client certificate" do
      req = request("/", client_cert: build_client_cert("Bucky"))
      
      assert body(req) =~ "Hello, Bucky!"
    end
  end
end
