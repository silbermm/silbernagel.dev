defmodule Mix.Tasks.Content.New do
  @moduledoc """
  Create new content for the site.

  Pass in the content type you want to create, and properties to set: 

  # Valid content-types:
    * post
    * note

  # Properties:
    * --title         string                 The entry title (required)
    * --author        string                 The author of the entry
    * --tags          comma seperated string list of tags
    * --description   string                 A description of the entry
    * --draft


  # Examples
    * `mix content.new post --title "My blog post"`
    * `mix content.new note --title "Notebook Entry #2"`

  """

  @valid_content_types ~w(post note)
  @default_author "Matt Silbernagel"

  defmodule Error do
    defexception [:message]
  end

  @shortdoc "What to put here?"
  def run(argv) do
    {opts, [content_type | _]} = OptionParser.parse!(argv, strict: [title: :string])

    content_type = validate_content_type(content_type)

    IO.puts("Creating new #{content_type} entry")

    str = ~s"""
    %{
      title: "#{opts[:title]}",
      author: "#{@default_author}",
      tags: ~w(),
      description: "",
      draft: true
    }
    ---

    # New Entry

    Content goes here
    """

    date = DateTime.utc_now()
    filename = String.downcase(opts[:title]) |> String.replace(" ", "-")

    # write this string to a new file in priv 
    folder = Path.join(File.cwd!(), "priv/#{content_type}s/#{date.year}")
    file = Path.join(folder, "#{Calendar.strftime(date, "%m-%d")}-#{filename}.md")

    # make sure the folder exists
    _ = File.mkdir_p!(folder)

    # does the file already exist?
    if File.exists?(file) do
      raise Error, message: "#{content_type} already exists at #{file}"
    end

    {:ok, file} = File.open(file, [:write])
    IO.write(file, str)
    File.close(file)
  end

  defp validate_content_type(content_type) when content_type in @valid_content_types,
    do: content_type

  defp validate_content_type(invalid),
    do:
      raise(Error,
        message: "Invalid content type (#{invalid}), use one of #{inspect(@valid_content_types)}"
      )
end
