defmodule Server do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :server]
  end

  def init(:ok) do
    Logger.info "Init Server module"
    {:ok, []}
  end

  def redis_get_list(key) do
    {:ok, list} = Redix.command :redis, ~w(LRANGE #{key} 0 -1)
    Enum.map(list, fn x -> URI.decode(x) end)
  end

  def get_list(user) do
    GenServer.call(:server, {:todo, user})
  end

  def help() do
    "Todo list bot!\nUse /todo to get your list\n/add [element] to add something\n/del [element] to remove something\n/subscribe to get your todo list every day at 9:00 AM! 🕘"
  end

  def format_list(user) do
    case redis_get_list(user) do
      [] -> {:empty, "Your list is empty!"}
      user_list -> {:ok, List.foldr(user_list, "📜 <b>Here is your todo list:</b> 📜\n", fn x,acc -> acc <> " - " <> x <> "\n" end)}
    end
  end

  def remove_redis(key, value) do
    case Redix.command(:redis, ~w(LREM #{key} 1 #{URI.encode(value)})) do
      {:ok, _} -> Logger.info "#{value} removed from #{key}"
      _ -> Logger.error "Could not remove #{value} from #{key}"
    end
  end

  def remove_hash_redis(key, text) do
    hash = Utils.hash_md5(text)
    case Redix.command(:redis, ~w(DEL #{key}:#{hash})) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end

  def add_to_list(user, elem) do
    GenServer.call(:server, {:add, user, elem})
  end

  def naisdel_from_list(elem) do
    GenServer.call(:server, {:naisdel, elem})
  end

  def del_from_list(user, elem) do
    GenServer.call(:server, {:del, user, elem})
  end

  def handle_call({:todo, user}, _from, state) do
    Logger.info("Retrieving list to #{user}")
    {:reply, format_list(user), state}
  end

  def handle_call({:add, user, elem}, _from, state) do
    elem = String.replace(elem, "<", "{") |> String.replace(">", "}")
    Logger.info("Adding #{elem} to #{user}")
    case Redix.command(:redis, ~w(LPUSH #{user} #{URI.encode(elem)})) do
      {:ok, _} ->
        Utils.save_hash(user, elem)
        Logger.info "#{elem} added to #{user}"
      _ -> Logger.info "Could not add #{elem} from #{user}"
    end
    {:reply, "<b>#{elem}</b> added.", state}
  end

  def handle_call({:naisdel, elem}, _from, state) do
    Logger.info("Removing #{elem}")

    r = with {:ok, id, text} <- Utils.get_from_hash(elem),
         {:ok, _} <- Redix.command(:redis, ~w(LREM #{id} 1 #{URI.encode(text)})),
         {:ok, _} <- Redix.command(:redis, ~w(DEL #{elem})) do
      true
    else
      _ -> false
    end

    {:reply, r, state}
  end

  def handle_call({:del, user, elem}, _from, state) do
    Logger.info("Removing #{elem} from #{user}")
    case Redix.command(:redis, ~w(LREM #{user} 1 #{URI.encode(elem)})) do
      {:ok, 0} -> {:reply, "<b>#{elem}</b> is not in your list!", state}
      {:ok, _} ->
        Server.remove_hash_redis(user, elem)
        Logger.info "#{elem} removed from #{user}"
        {:reply, "<b>#{elem}</b> removed!", state}
      _ -> Logger.error "Could not remove #{elem} from #{user}"
    end
  end
end
