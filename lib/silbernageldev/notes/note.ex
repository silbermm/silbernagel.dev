defmodule Silbernageldev.Notes.Note do
  @moduledoc false

  @enforce_keys [:author, :body, :datetime]
  defstruct [:author, :body, :tags, :datetime, :draft, :reply_to]

  def build(filename, attrs, body) do
    [year, month_day_time] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)

    [month, day, time] = String.split(month_day_time, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    time = Time.from_iso8601!(time)
    datetime = DateTime.new!(date, time)
    struct!(__MODULE__, [datetime: datetime, body: body] ++ Map.to_list(attrs))
  end
end
