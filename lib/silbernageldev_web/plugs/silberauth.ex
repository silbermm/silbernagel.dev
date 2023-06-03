defmodule SilbernageldevWeb.Plugs.Silberauth do
  @moduledoc false
  use GenServer
  use PlugGPGVerify
  use Silbernageldev.OpenTelemetry

  trace_all(kind: :internal)

  # my user with a generated uuid
  @users [
    %{
      id: "7af6ab9b-b96a-442e-bd24-4e91db89ae52",
      email: "matt@silbernagel.dev"
    }
  ]

  # a ets table to hold info for logging in
  @table :user_challenges

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, @users}
  end

  @impl true
  def find_user_by_email(user_email),
    do: GenServer.call(__MODULE__, {:find_user_by_email, user_email})

  @impl PlugGPGVerify
  def find_user_by_id(user_id), do: GenServer.call(__MODULE__, {:find_user_by_id, user_id})

  @impl PlugGPGVerify
  def gpg_verified(conn, user) do
    token = Phoenix.Token.sign(SilbernageldevWeb.Endpoint, "user_auth", user)
    Phoenix.Controller.json(conn, %{token: token})
  end

  @impl PlugGPGVerify
  def challenge_created(user, challenge),
    do: GenServer.call(__MODULE__, {:store_challenge, user, challenge})

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
    # @TODO: More checks here - particularly expiration of the challenge
    case res do
      nil ->
        {:reply, {:error, :invalid}, state}

      user ->
        {:reply, {:ok, Map.put_new(user, :challenge, find_challenge_for(id))}, state}
    end
  end

  @impl GenServer
  def handle_call({:store_challenge, user, challenge}, _from, state) do
    res = :ets.insert(@table, {user.id, user, challenge})
    {:reply, res, state}
  end

  defp find_challenge_for(user_id) do
    case :ets.lookup(@table, user_id) do
      [{_id, _, res}] ->
        res

      _other ->
        ""
    end
  end
end
