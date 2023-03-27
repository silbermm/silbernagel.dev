defmodule SilbernageldevWeb.Controllers.NotesController do
  use SilbernageldevWeb, :controller

  alias Silbernageldev.Notes

  def create(conn, params) do
    params
    |> Notes.create()
    |> case do
      {:ok, note} ->
        json(conn, note)

      {:error, err_changeset} ->
        IO.inspect(err_changeset)

        conn
        |> put_status(500)
        |> json(%{})
    end
  end

  def publish(conn, %{"note_id" => note_id}) do
    note_id
    |> Notes.publish()
    |> case do
      {:ok, note} ->
        json(conn, note)

      {:error, err_changeset} ->
        IO.inspect(err_changeset)

        conn
        |> put_status(500)
        |> json(%{})
    end
  end

  def get(conn, %{"note_id" => note_id}) do
    note = Notes.get(note_id)
    conn
    |> put_status(200)
    |> json(note)
  end

  def list(conn, %{"limit" => limit, "offset" => offset} = params) do
    draft_status = Map.get(params, "draft", false)
    notes = Notes.all(limit: limit, offset: offset, draft: draft_status)
    do_list(conn, notes, draft_status)
  end

  def list(conn, params) do
    draft_status = Map.get(params, "draft", false)
    notes = Notes.all(limit: 50, draft: draft_status)
    do_list(conn, notes, draft_status)
  end

  defp do_list(conn, notes, draft_status) do
    total = Notes.total(draft: draft_status)

    conn
    |> put_status(200)
    |> json(%{notes: notes, total: total})
  end
end
