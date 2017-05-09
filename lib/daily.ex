defmodule Daily do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :daily]
  end

  def init(:ok) do
    Logger.info "Init Daily module"

    # case Redix.command(:redis, ~w(LRANGE daily 0 -1)) do
    #   {:ok, []} -> ""
    #   {:ok, ids} -> Enum.map(ids, fn id -> Process.send_after(:daily, {:spam, id}, millis_to_next_day()) end)
    # end

    {:ok, []}
  end

  # defp millis_to_next_day() do
  #   now = Timex.now("Europe/Madrid")
  #   tomorrow = Timex.shift(Timex.beginning_of_day(now), days: 1, hours: 9)
  #   Timex.diff(tomorrow, now, :milliseconds)
  # end

  def get_subscriptors() do
    {:ok, list} = Redix.command(:redis, ~w(LRANGE daily 0 -1))
    list
  end

  def subscribe(id) do
    case Integer.to_string(id) in get_subscriptors() do
      true -> "You are already subscribed! 😃"
      false ->
        # Process.send_after(:daily, {:spam, id}, millis_to_next_day())
        Redix.command(:redis, ~w(LPUSH daily #{id}))
        Logger.info "User #{id} subscribed to daily messages"
        "❤️ *Subscribed* to daily reminders! ❤️"
    end
  end

  def unsubscribe(id) do
    case Integer.to_string(id) in get_subscriptors() do
      true ->
        Redix.command(:redis, ~w(LREM daily 1 #{id}))
        "*Unsubscribed* from daily reminders... 😢"
      false -> "You are not subscribed.\nDo you want to give it a try?\n/subscribe"
    end
  end

  # def build_message(message) do
  #   refran = Refraner.get_all_refranes |> Enum.random
  #   "Well hello! Here is the saying of the day!\n_" <> refran  <> "_\n\n" <> message
  # end

  def build_message(message) do
    "Well hello!\nHope you have a great day! 😃\n\n" <> message
  end

  def spam() do
    Logger.info "Sending daily reminders"
    Daily.get_subscriptors |> Enum.map(&Daily.send_list/1)
  end

  def send_list(id) do
    message = Server.get_list(id) |> Daily.build_message
    Telex.send_message(id, message, bot: :daily_bot, parse_mode: "Markdown")
  end

  # def handle_info({:spam, id}, state) do
  #   Logger.info "Sending daily reminder to #{id}"
  #   tomorrow = 86_400_000 # 24 hours
  #   message = Server.get_list(id) |> Daily.build_message
  #   Telex.send_message(id, message, bot: :daily_bot, parse_mode: "Markdown")
  #   Process.send_after(:daily, {:spam, id}, tomorrow)
  #   {:noreply, state}
  # end
end
