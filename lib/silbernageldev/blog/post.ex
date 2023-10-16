defmodule Silbernageldev.Blog.Post do
  @moduledoc false

  @type t :: %{
          id: binary(),
          author: binary(),
          title: binary(),
          body: binary(),
          gemtext: binary(),
          description: binary(),
          tags: binary(),
          date: Date.t()
        }

  @enforce_keys [:id, :author, :title, :body, :description, :tags, :date]
  defstruct [:id, :author, :title, :body, :description, :tags, :date, :draft, :reply_to, :gemtext]

  def build(filename, attrs, body) do
    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    html = 
      body 
      |> GemtextToHTML.render_to_string(components: GemtextToHTML.DefaultComponents) 
      |> NimblePublisher.Highlighter.highlight()

    struct!(__MODULE__, [id: id, date: date, body: html, gemtext: body] ++ Map.to_list(attrs))
  end

  def parse(path, contents) do
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] ->
        {:error, "could not find separator --- in #{inspect(path)}"}

      [code, body] ->
        case Code.eval_string(code, []) do
          {%{} = attrs, _} ->
            {:ok, attrs, body}

          {other, _} ->
            {:error,
             "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
        end
    end
    |> case do
      {:ok, attrs, body} ->
        {attrs, body}

      {:error, message} ->
        raise """
        #{message}

        Each entry must have a map with attributes, followed by --- and a body. For example:

            %{
              title: "Hello World"
            }
            ---
            Hello world!

        """
    end
  end
end
