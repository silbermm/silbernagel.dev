defmodule Silbernageldev.WebMentions.Supervisor do
  use Supervisor

  alias Silbernageldev.WebMentions.SenderSupervisor
  alias Silbernageldev.WebMentions.Queue


  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Queue, []},
      SenderSupervisor.child_spec([])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
