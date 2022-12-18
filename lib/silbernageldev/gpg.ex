defmodule Silbernageldev.GPG do
  @doc false

  def get_gpg_key() do
    file = Application.app_dir(:silbernageldev, "/priv/static/silbernagel.asc")
    File.read!(file)
  end
end
