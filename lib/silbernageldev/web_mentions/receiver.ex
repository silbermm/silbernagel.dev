defmodule Silbernageldev.WebMentions.Receiver do
  use Libmention.Incoming.Receiver

  @impl true
  def validate(target_url) do
    :ok
  end

end
