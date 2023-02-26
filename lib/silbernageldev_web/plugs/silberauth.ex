defmodule SilbernageldevWeb.Plugs.Silberauth do
  @moduledoc """
  # TODO:
  """
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
  def find_user_by_email(user_email),
    do: GenServer.call(__MODULE__, {:find_user_by_email, user_email})

  @impl GPGAuth
  def find_user_by_id(user_id), do: GenServer.call(__MODULE__, {:find_user_by_id, user_id})

  @impl GPGAuth
  def gpg_verified(conn, user) do
    token = Phoenix.Token.sign(SilbernageldevWeb.Endpoint, "user_auth", user, max_age: 84000)
    Phoenix.Controller.json(conn, %{token: token})
  end

  @impl GPGAuth
  def challenge_created(user, challenge, plain_text),
    do: GenServer.call(__MODULE__, {:store_challenge, user, challenge, plain_text})

  @impl GenServer
  def handle_call({:find_user_by_email, email}, _from, state) do
    case Enum.find(state, &(&1.email == email)) do
      nil -> {:reply, {:error, :not_found}, state}
      res -> {:reply, {:ok, res}, state}
    end
  end

  @impl GenServer
  def handle_call({:find_user_by_id, id}, _from, state) do
    res = Enum.find(state, &(&1.id == id))
    # TODO: More checks here - particularly expiration of the challenge
    case res do
      nil ->
        {:reply, {:error, :invalid}, state}

      user ->
        {:reply, {:ok, Map.put_new(user, :challenge, find_challenge_for(id))}, state}
    end
  end

  @impl GenServer
  def handle_call({:store_challenge, user, challenge, plain_text}, _from, state) do
    res = :ets.insert(@table, {user.id, user, challenge, plain_text})
    {:reply, res, state}
  end

  defp find_challenge_for(user_id) do
    case :ets.lookup(@table, user_id) do
      [{_id, _, _, res}] ->
        res

      other ->
        ""
    end
  end
end
