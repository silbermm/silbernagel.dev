defmodule Silbernageldev.WebMentions.Queue do
  @moduledoc """
  A queue that takes and queues webmention requests
  and sends them to the webmention processor at a 
  configurable rate limited time
  """
  use GenServer

  alias __MODULE__
  require Logger

  @type id :: binary()
  @table_name :queue_lookup

  defstruct [:id, :target, :source, :status, :queued_at, :last_updated]

  defp new(id, source, target) do
    now = DateTime.utc_now()

    %Queue{
      id: id,
      source: source,
      target: target,
      status: :queued,
      queued_at: now,
      last_updated: now
    }
  end

  defp transition(q, {:validity, false}), do: %{q | status: :invalid, last_updated: DateTime.utc_now()}
  defp transition(q, {:validity, true}), do: %{q | status: :valid, last_updated: DateTime.utc_now()}

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(opts) do
    :ets.new(@table_name, [:set, :public, :named_table])
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, :queue.new()}
  end

  @doc """
  Add a new request to the queue. 

  Accepts a source url and a target url.
  """
  @spec add(binary(), binary()) :: id()
  def add(source, target), do: GenServer.call(__MODULE__, {:add, source, target})



  #### SERVER CALLBACKS
  @impl true
  def handle_call({:add, source, target}, _from, queue) do
    # @TODO: verify this request isn't already queued
    id = UUID.uuid4()
    data = new(id, source, target)
    :ets.insert(@table_name, {id, data})
    q = :queue.in(id, queue)
    {:reply, data, q, {:continue, {:start_verification, id}}}
  end

  @impl true
  def handle_continue({:start_verification, id}, queue) do
    Task.Supervisor.async_nolink(Silbernageldev.TaskSupervisor, fn ->
      # check validity and return result
      {id, valid?(id)}
    end)
    {:noreply, queue}
  end

  @impl true
  def handle_info({ref, {id, valid?}}, queue) do
    Logger.info("updating ets")
    Process.demonitor(ref, [:flush])
    # update the state of the item in ets
    [{_, data}] = :ets.lookup(@table_name, id)
    data = transition(data, {:validity, valid?})
    :ets.insert(@table_name, {id, data})
    {:noreply, queue}
  end

    # The task failed
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    # Log and possibly restart the task...
    {:noreply, state}
  end

  defp valid?(_id) do
    true
  end
end
