defmodule SilbernageldevWeb.Live.GPGLive do
  use SilbernageldevWeb, :blog_live_view

  @impl true
  def mount(_, _, socket) do
    {:ok, assign(socket, :gpg_public_key, Silbernageldev.GPG.get_gpg_key())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center w-full m-auto pb-4"> 
        <.link
          class="text-gray-500 dark:text-slate-400 hover:text-orange-400"
          href="https://keyoxide.org/wkd/matt%40silbernagel.dev"
          target="_blank"
        >
          Proof of identity
        </.link>
      </div>
      <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200 pb-4">Use GPG to import</h3>
      <pre class="bg-black text-gray-200 whitespace-pre-wrap"><code>
      gpg --locate-keys --auto-key-locate clear,nodefault,wkd matt@silbernagel.dev
      </code></pre>
      <div id="pgp-key" class="flow-root" phx-hook="CopyPGP">
        <div class="grid grid-cols-3 grid-flow-col gap-2 py-6">
          <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200">OpenPGP Key</h3>
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
                href={~p"/gpg/download"}
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
