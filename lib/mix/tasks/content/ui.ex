defmodule Mix.Tasks.Content.UI do
  @behaviour Ratatouille.App

  import Ratatouille.View
  alias Ratatouille.Runtime.Command

  @impl true
  def init(_context) do
    token = Mix.Tasks.Content.Store.Token.get_token()
    url = SilbernageldevWeb.Endpoint.url()
    notes_url = SilbernageldevWeb.Router.Helpers.api_notes_url(SilbernageldevWeb.Endpoint, :list)

    get_current_notes =
      Command.new(
        fn ->
          Req.get(notes_url, auth: {:bearer, token})
        end,
        :fetch_current_notes
      )

    {%{
       title: "silbernagel.dev",
       url: url,
       notes: %{data: [], total: 0}
     }, get_current_notes}
  end

  @impl true
  def update(model, msg) do
    case msg do
      {:fetch_current_notes, {:ok, res}} ->
        data = Map.get(res.body, "notes")
        total = Map.get(res.body, "total")

        %{model | notes: %{data: data, total: total}}

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
                table_row do
                  table_cell(content: show_note_title(note))
                end
              end)
            end
          end
        end

        column(size: 8) do
          panel title: "Data", height: :fill do
            label(content: "data")
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
end
