defmodule Mix.Tasks.Content.UI do
  @behaviour Ratatouille.App

  import Ratatouille.View

  @impl true
  def init(_context) do
    %{
      title: "silbernagel.dev"
    }
  end

  @impl true
  def update(model, _msg) do
    model
  end

  @impl true
  def render(_model) do
    view bottom_bar: bottom_bar() do
      row do
        column(size: 12) do
          panel title: "Info" 
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
