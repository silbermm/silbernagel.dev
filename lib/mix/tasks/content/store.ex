defmodule Mix.Tasks.Content.Store do
  @moduledoc """
  A simple module to save and retrieve the access token
  """

  use GenServer

  @token_table :tokens
  @url_table :urls

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    :ets.new(@token_table, [:set, :protected, :named_table])
    :ets.new(@url_table, [:set, :protected, :named_table])
    {:ok, %{}}
  end

  def save_token(token), do: GenServer.cast(__MODULE__, {:save_token, token})
  def get_token(), do: GenServer.call(__MODULE__, :get_token)

  def save_url(url), do: GenServer.cast(__MODULE__, {:save_url, url})
  def get_url(), do: GenServer.call(__MODULE__, :get_url)

  @impl true
  def handle_cast({:save_token, token}, state) do
    _ = :ets.insert(@token_table, {token})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:save_url, url}, state) do
    _ = :ets.insert(@url_table, {url})
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    token = :ets.first(@token_table)
    {:reply, token, state}
  end

  @impl true
  def handle_call(:get_url, _from, state) do
    url = :ets.first(@url_table)
    {:reply, url, state}
  end
end
