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
       notes: %{notes: [], total: 0}
     }, get_current_notes}
  end

  @impl true
  def update(model, msg) do
    case msg do
      {:fetch_current_notes, {:ok, res}} ->
        %{model | notes: Map.get(res.body, "notes")}

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
        column(size: 3) do
          panel title: "Notes", height: :fill do
            table do
              table_row do
                table_cell(content: "Column 1")
              end

              table_row do
                table_cell(content: "a")
              end
            end
          end
        end

        column(size: 9) do
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
end
