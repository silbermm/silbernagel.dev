defmodule Mix.Tasks.Content.UI do
  @behaviour Ratatouille.App

  import Ratatouille.View
  import Ratatouille.Constants

  alias Ratatouille.Runtime.Command
  alias Mix.Tasks.Content.State

  @impl true
  def init(_context) do
    token = Mix.Tasks.Content.Store.get_token()
    url = Mix.Tasks.Content.Store.get_url()

    state = State.new(url, token)
    {state, get_current_notes_command(url, token)}
  end

  @impl true
  def update(model, msg) do
    case msg do
      {:event, %{ch: ?j}} ->
        State.set_next_selected_note(model)

      {:event, %{ch: ?k}} ->
        State.set_previous_selected_note(model)

      {:fetch_current_notes, data} ->
        State.add_notes(model, data)

      _ ->
        model
    end
  end

  @impl true
  def render(model) do
    view bottom_bar: bottom_bar() do
      row do
        column(size: 12) do
          panel title: "Info" do
            label(content: "URL", attributes: [:bold, :underline])

            label do
              text(
                content: model.url,
                color: :blue,
                attributes: [:bold]
              )
            end
          end
        end
      end

      row do
        column(size: 4) do
          panel title: "Notes", height: :fill do
            table do
              Enum.map(model.notes.data, fn note ->
                opts =
                  if Map.get(note, "selected") do
                    [background: color(:cyan), color: color(:black)]
                  else
                    []
                  end

                table_row(opts) do
                  table_cell(content: show_note_title(note))
                end
              end)
            end
          end
        end

        column(size: 8) do
          panel title: "Data", height: :fill do
            label(content: State.selected_note_content(model))
          end
        end
      end
    end
  end

  defp bottom_bar() do
    bar do
      label(
        content: "[j/k or ↑/↓ to move] [space to show] [c to copy] [q to quit] [? for more help]"
      )
    end
  end

  defp show_note_title(%{"content" => content, "draft" => draft}) do
    case String.split_at(content, 20) do
      {c, rest} when rest == "" ->
        if draft do
          "DRAFT: #{c}"
        else
          c
        end

      {c, _rest} ->
        if draft do
          "DRAFT: #{c}..."
        else
          "#{c}..."
        end
    end
  end

  defp get_current_notes_command(url, token) do
    Command.new(
      fn ->
        case Req.get(url <> "/api/notes", auth: {:bearer, token}) do
          {:ok, %{body: body}} ->
            notes = Map.get(body, "notes")
            total = Map.get(body, "total")

            notes = Enum.map(notes, &Map.put_new(&1, "selected", false))
            %{data: notes, total: total}

          _ ->
            %{data: [], total: 0}
        end
      end,
      :fetch_current_notes
    )
  end
end
