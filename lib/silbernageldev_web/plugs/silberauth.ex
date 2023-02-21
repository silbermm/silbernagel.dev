defmodule SilbernageldevWeb.Plugs.Silberauth do
  use GenServer
  use GPGAuth

  @users [
    %{
      id: "7af6ab9b-b96a-442e-bd24-4e91db89ae52",
      email: "matt@silbernagel.dev"
    }
  ]

  @table :user_challenges

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, @users}
  end

  @impl GPGAuth
  def find_user(user_email), do: GenServer.call(__MODULE__, {:find_user, user_email})

  @impl GPGAuth
  def store_challenge_for(user, challenge),
    do: GenServer.call(__MODULE__, {:store_challenge, user, challenge})

  def find_challenge_for(user_id) do
    :ets.lookup(@table, user_id)
  end

  @impl GenServer
  def handle_call({:find_user, email}, _from, state) do
    res = Enum.find(state, &(&1.email == email))
    {:reply, res, state}
  end

  @impl GenServer
  def handle_call({:store_challenge, user, challenge}, _from, state) do
    res = :ets.insert(@table, {user.id, challenge})
    {:reply, res, state}
  end
end
