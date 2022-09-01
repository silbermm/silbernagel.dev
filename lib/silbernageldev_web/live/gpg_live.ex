defmodule SilbernageldevWeb.Live.GPGLive do
  use SilbernageldevWeb, :blog_live_view

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, :gpg_public_key, Silbernageldev.GPG.get_gpg_key())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div id="pgp-key" class="flow-root" phx-hook="CopyPGP">
        <div class="grid grid-cols-3 grid-flow-col gap-2 py-6">
          <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200">GPG Public Key</h3>
          <div class="col-span-2 text-right">
            <span class="relative z-0 inline-flex rounded-md shadow-sm">
              <button
                type="button"
                id="pgp-copy-btn"
                class="relative inline-flex items-center rounded-l-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              >
                Copy
              </button>

              <a
                type="button"
                class="relative -ml-px inline-flex items-center rounded-r-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                href={Routes.gpg_path(@socket, :download)}
              >
                Download
              </a>
            </span>
          </div>
        </div>
        <div class="px-8 py-8 bg-white text-black overflow-scroll border border-gray-200">
          <pre> <%= @gpg_public_key %> </pre>
        </div>
      </div>
    </div>
    """
  end
end
