defmodule Server do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :server]
  end

  def init(:ok) do
    Bunt.puts "Running..."
    {:ok, keys} = Redix.command :redis, ~w(KEYS *)
    init_state = Enum.map(keys, &redis_get_list/1)
    |> List.foldl(%{}, fn {key, value}, acc -> Map.put(acc, key, value) end)

    IO.inspect init_state

    {:ok, init_state} # %{chatid: [ todolist ]}
  end

  def redis_get_list(key) do
    {:ok, list} = Redix.command :redis, ~w(LRANGE #{key} 0 -1)
    {key, list}
  end

  def get_list(user) do
    GenServer.call(:server, {:todo, user})
  end

  def format_list(state, user) do
    case state do
      %{^user => user_list} ->
        List.foldl(user_list, "Here is your todo list:\n", fn x,acc -> acc <> " - " <> x <> "\n" end)
      _ ->
        "Your list is empty!"
    end
  end

  def add_to_list(user, elem) do
    GenServer.call(:server, {:add, user, elem})
  end

  def remove_redis(key, value) do
    case Redix.command(:redis, ~w(LREM #{key} 1 #{value})) do
      {:ok, _} -> Logger.info "#{value} removed from #{key}"
      _ -> Logger.error "Could not remove #{value} from #{key}"
    end
  end

  def del_from_list(user, elem) do
    GenServer.call(:server, {:del, user, elem})
  end

  def handle_call({:todo, user}, _from, state) do
    Logger.info("Retrieving list to #{user}")
    {:reply, format_list(state, user), state}
  end

  def handle_call({:add, user, elem}, _from, state) do
    case state do
      %{^user => user_list} ->
        Logger.info("Adding #{elem} to #{user}")
        Redix.command(:redis, ~w(LPUSH #{user} #{elem}))
        {:reply, "*#{elem}* added.", Map.put(state, user, [elem | user_list])}
      _ ->
        Logger.info("New user #{user}. Adding #{elem} to #{user}")
        Redix.command(:redis, ~w(LPUSH #{user} #{elem}))
        {:reply, "*#{elem}* added.", Map.put(state, user, [elem])}
    end
  end

  def handle_call({:del, user, elem}, _from, state) do
    case state do
      %{^user => user_list} ->
        case List.delete(user_list, elem) do
          ^user_list -> {:reply, "*#{elem}* is not in your list!", state}
          new_list ->
            Logger.info("Removing #{elem} from #{user}")
            Redix.command(:redis, ~w(LREM #{user} 1 #{elem}))
            {:reply, "*#{elem}* removed!", Map.put(state, user, new_list)}
        end
      _ -> {:reply, "*#{elem}* is not in your list!", state}
    end
  end
end
