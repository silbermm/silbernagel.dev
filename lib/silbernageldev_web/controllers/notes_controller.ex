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
end
