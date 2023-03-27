defmodule Mix.Tasks.Content.Store.Token do
  @moduledoc """
  A simple module to save and retrieve the access token
  """

  use GenServer
  
  @table :tokens

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  def save_token(token), do: GenServer.cast(__MODULE__, {:save_token, token})

  def get_token(), do: GenServer.call(__MODULE__, :get_token)

  @impl true
  def handle_cast({:save_token, token}, state) do
    res = :ets.insert(@table, {token})
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    token = :ets.first(@table)
    {:reply, token, state}
  end
end
