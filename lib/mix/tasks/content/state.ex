defmodule Mix.Tasks.Content.State do
  @moduledoc """
  Holds the state of the UI

  Provides helper functions for changing the state
  """

  alias __MODULE__

  defstruct [:title, :token, :url, :notes]

  def new(url, token) do
    %State{url: url, token: token, notes: %{data: [], total: 0}}
  end

  def add_notes(%State{} = state, notes) do
    %{state | notes: notes}
  end

  def set_previous_selected_note(%State{notes: notes} = state) do
    notes.data
    |> Enum.with_index()
    |> Enum.find(fn {note, _idx} ->
      Map.get(note, "selected")
    end)
    |> case do
      nil ->
        # no note was selected, so no note to deselect
        state

      {_note, idx} ->
        notes =
          if idx > 0 do
            # set the note at idx - 1 to selected
            notes = %{notes | data: set_note_selected_at(notes, idx - 1)}

            # set the note at idx to unselected
            %{notes | data: set_note_unselected_at(notes, idx)}
          else
            notes
          end

        %{state | notes: notes}
    end
  end

  def set_next_selected_note(%State{notes: notes} = state) do
    notes.data
    |> Enum.with_index()
    |> Enum.find(fn {note, _idx} ->
      Map.get(note, "selected")
    end)
    |> case do
      nil ->
        # no note was selected, so select the first one
        notes = %{notes | data: set_note_selected_at(notes, 0)}
        %{state | notes: notes}

      {_note, idx} ->
        # set the note at idx + 1 to selected
        notes = %{notes | data: set_note_selected_at(notes, idx + 1)}

        notes =
          if idx + 1 == notes.total do
            notes
          else
            %{notes | data: set_note_unselected_at(notes, idx)}
          end

        %{state | notes: notes}
    end
  end

  def selected_note_content(%State{notes: notes}) do
    case Enum.find(notes.data, &Map.get(&1, "selected")) do
      nil -> ""
      note -> Map.get(note, "content")
    end
  end

  defp set_note_selected_at(%{data: notes, total: total}, idx) when idx == total, do: notes

  defp set_note_selected_at(%{data: notes}, idx) do
    note = Enum.at(notes, idx)
    note = Map.put(note, "selected", true)
    List.replace_at(notes, idx, note)
  end

  # defp set_note_unselected_at(%{data: notes, total: total}, idx) when idx + 1 == total, do: notes

  defp set_note_unselected_at(%{data: notes}, idx) do
    note = Enum.at(notes, idx)
    note = Map.put(note, "selected", false)
    List.replace_at(notes, idx, note)
  end
end
