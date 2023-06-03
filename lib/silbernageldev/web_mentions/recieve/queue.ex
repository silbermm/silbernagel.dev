defmodule Silbernageldev.WebMentions.Queue do
  @moduledoc """
  A queue that takes and queues webmention requests
  and sends them to the webmention processor at a 
  configurable rate limited time
  """
  use GenServer

  alias __MODULE__
  require Logger

  @log_prefix "[WebMention Queue] | "
  @type id :: binary()
  @table_name :queue_lookup

  defstruct [:id, :target, :source, :status, :content, :queued_at, :last_updated]

  defp new(id, source, target) do
    now = DateTime.utc_now()

    %Queue{
      id: id,
      source: source,
      target: target,
      status: :queued,
      content: "",
      queued_at: now,
      last_updated: now
    }
  end

  defp transition(q, {:validity, false}),
    do: %{q | status: :invalid, last_updated: DateTime.utc_now()}

  defp transition(q, {:validity, true}),
    do: %{q | status: :valid, last_updated: DateTime.utc_now()}

  defp add_content(q, content), do: %{q | content: content, last_updated: DateTime.utc_now()}

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts) do
    :ets.new(@table_name, [:set, :public, :named_table])
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts), do: {:ok, :queue.new()}

  @doc """
  Add a new request to the queue. 

  Accepts a source url and a target url.
  """
  @spec add(binary(), binary()) :: id()
  def add(source, target), do: GenServer.call(__MODULE__, {:add, source, target})

  @doc """
  List the current queue of requests.
  """
  @spec list() :: list(map())
  def list(), do: GenServer.call(__MODULE__, :list)

  #### SERVER CALLBACKS
  @impl true
  def handle_call({:add, source, target}, _from, queue) do
    # @TODO: verify this request isn't already queued
    id_source = Enum.sort([source, target])
    id = :erlang.phash2(id_source)

    if :queue.member(id, queue) do
      {:reply, {:error, :already_queued}, queue}
    else
      data = new(id, source, target)
      :ets.insert(@table_name, {id, data})
      q = :queue.in(id, queue)
      {:reply, {:ok, data}, q, {:continue, {:start_verification, id}}}
    end
  end

  def handle_call(:list, _from, queue) do
    list =
      :queue.fold(
        fn id, acc ->
          [{_, data}] = :ets.lookup(@table_name, id)
          [data | acc]
        end,
        [],
        queue
      )

    {:reply, list, queue}
  end

  @impl true
  def handle_continue({:start_verification, id}, queue) do
    Task.Supervisor.async_nolink(Silbernageldev.TaskSupervisor, fn ->
      # check validity and return result
      {id, determine_validity(id)}
    end)

    {:noreply, queue}
  end

  @impl true
  def handle_info({ref, {id, validity}}, queue) do
    Logger.info("updating ets")
    Process.demonitor(ref, [:flush])
    # update the state of the item in ets
    [{_, data}] = :ets.lookup(@table_name, id)

    data =
      case validity do
        {:ok, document} ->
          data
          |> transition({:validity, true})
          |> add_content(Floki.raw_html(document))

        {:error, _} ->
          transition(data, {:validity, false})
      end

    :ets.insert(@table_name, {id, data})
    {:noreply, queue}
  end

  # The task failed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Log and possibly restart the task...
    {:noreply, state}
  end

  defp determine_validity(id) do
    [{_, data}] = :ets.lookup(@table_name, id)
    html = Req.get!(data.source, headers: [Accept: "text/html"])

    case Floki.parse_document(html.body) do
      {:ok, document} ->
        a = Floki.find(document, ~s{a[href="#{data.target}"]})

        if Enum.empty?(a) do
          {:error, :invalid_source_link}
        else
          IO.inspect "GOOD"
          {:ok, document}
        end

      {:error, reason} ->
        Logger.warn("#{@log_prefix} Unable to parse html -- #{reason}")
        false
    end
  end
end
