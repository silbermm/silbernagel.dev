defmodule SilbernageldevWeb.Live.PGPLive do
  use SilbernageldevWeb, :blog_live_view

  @pgp_public_key ~S"""
  -----BEGIN PGP PUBLIC KEY BLOCK-----

  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
  gwhe
  =SxGk
  -----END PGP PUBLIC KEY BLOCK-----
  """

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, :pgp_public_key, @pgp_public_key)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div id="pgp-key" class="flow-root" phx-hook="CopyPGP">
        <div class="grid grid-cols-3 grid-flow-col gap-2 py-6">
          <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200">PGP Public Key</h3>
          <div class="col-span-2 text-right">
            <span class="relative z-0 inline-flex rounded-md shadow-sm">
              <button
                type="button"
                id="pgp-copy-btn"
                class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              >
                Copy
              </button>

              <button
                type="button"
                class="relative -ml-px inline-flex items-center rounded-r-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              >
                Download
              </button>
            </span>
          </div>
        </div>
        <div class="px-8 py-8 bg-white text-black">
          <pre> <%= @pgp_public_key %> </pre>
        </div>
      </div>
    </div>
    """
  end
end
