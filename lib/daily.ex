defmodule Daily do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :daily]
  end

  def init(:ok) do
    Logger.info "Init Daily module"
    {:ok, []}
  end

  def get_subscriptors() do
    {:ok, list} = Redix.command(:redis, ~w(SMEMBERS daily))
    list
  end

  def subscribe(id) do
    case Integer.to_string(id) in get_subscriptors() do
      true -> "You are already subscribed! 😃"
      false ->
        # Process.send_after(:daily, {:spam, id}, millis_to_next_day())
        Redix.command(:redis, ~w(SADD daily #{id}))
        Logger.info "User #{id} subscribed to daily messages"
        "❤️ <b>Subscribed</b> to daily reminders! ❤️"
    end
  end

  def unsubscribe(id) do
    case Redix.command(:redis, ~w(SREM daily #{id})) do
      {:ok, 1} ->
        "<b>Unsubscribed</b> from daily reminders... 😢"
      {:ok, 0} ->
	"You are not subscribed.\nDo you want to give it a try?\n/subscribe"
    end
  end

  def build_message(message) do
    refran = Refraner.get_all_refranes |> (fn x -> x ++ ["No hay que reinventar la rueda, sino hacerla mas redonda."] end).() |> Enum.random
    "Well hello!\nHope you have a great day!\nHere is the say of the day:\n - <i>" <> refran  <> "</i>\n\n" <> message
  end

  def build_empty_message() do
    refran = Refraner.get_all_refranes |> (fn x -> x ++ ["No hay que reinventar la rueda, sino hacerla mas redonda."] end).() |> Enum.random
    "Your list is empty! But here you have a say :D\n\n<i>" <> refran <> "</i>"
  end

  def spam() do
    Logger.info "Sending daily reminders"
    Daily.get_subscriptors |> Enum.map(&Daily.send_list/1)
  end

  def send_list(id) do
    message = case Server.get_list(id) do
                {:ok, list} -> list |> Daily.build_message
                {:empty, _} -> Daily.build_empty_message
    end
    # message = list |> Daily.build_message
    Telex.send_message(id, message, bot: :daily_bot, parse_mode: "HTML", disable_web_page_preview: true)
  end
end
