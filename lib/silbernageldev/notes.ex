defmodule Silbernageldev.Notes do
  @moduledoc """
  This is what builds my [notes](https://indieweb.org/note)
  """

  alias Silbernageldev.Notes.Note

  use NimblePublisher,
    build: Note,
    from: Application.app_dir(:silbernageldev, "priv/content/notes/**/*.md"),
    as: :notes,
    highlighters: [:makeup_elixir, :makeup_erlang, :makeup_html5, :makeup_eex]

  # The @notes variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all notes by descending date.
  @notes @notes
         |> Enum.sort_by(& &1.datetime, {:desc, DateTime})
         |> then(fn notes ->
           unless Mix.env() == :dev do
             Enum.reject(notes, &Map.get(&1, :draft, false))
           else
             notes
           end
         end)

  @doc "Export all notes"
  def all_notes, do: @notes

  defmodule NotFoundError, do: defexception([:message, plug_status: 404])

  def get_note_by_timestamp(timestamp) do
    Enum.find(@notes, &(&1.timestamp == timestamp)) ||
      raise NotFoundError, "note with timestamp=#{timestamp} not found"
  end
end
