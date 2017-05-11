defmodule DailyBot.Bot do
  @bot :daily_bot
  def bot(), do: @bot

  use Telex.Bot, name: @bot
  use Telex.Dsl

  require Logger

  def handle({:command, "start", msg}, name, _) do
    answer msg, "<b>Hello there!</b>\nReady for the daily spam?", bot: name, parse_mode: "HTML"
  end

  def handle({:command, "todo", %{chat: %{id: id}}  =msg}, name, _) do
    answer msg, Server.get_list(id), bot: name, parse_mode: "HTML", disable_web_page_preview: true
  end

  def handle({:command, "add", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer msg, Server.add_to_list(id, t), bot: name, parse_mode: "HTML"
  end

  def handle({:command, "del", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer msg, Server.del_from_list(id, t), bot: name, parse_mode: "HTML"
  end

  def handle({:command, "naisdel", %{chat: %{id: id}} = msg}, name, _) do
    markup = Utils.generate_del_keyboard(id)

    answer msg, "Select any element that you want to remove", reply_markup: markup, bot: name
  end

  def handle({:callback_query, %{data: "del:done"} = msg}, name, _) do
    message = "Enought removing things!"
    edit :inline, msg, message, bot: name, parse_mode: "HTML"
  end

  def handle({:callback_query, %{message: %{chat: %{id: id}}, data: "del:elem:" <> elem} = msg}, name, _) do
    if Server.naisdel_from_list(elem) do

      markup = Utils.generate_del_keyboard(id)
      case length(markup.inline_keyboard) do
        1 ->
          message = "Enought removing things!"
          edit :inline, msg, message, bot: name, parse_mode: "HTML"
        _ ->
          edit :inline, msg, "<b>Element removed!</b>\n\nSelect any element that you want to remove", reply_markup: markup, parse_mode: "HTML", bot: name
      end
    else
      Logger.error "Callback query matching error #{elem} (WTF NIGGI)"
    end
    # message = Server.naisdel_from_list(elem) <> "\n\nSelect any element that you want to remove"
    # Utils.del_hash_from_redis(elem)
    # markup = Utils.generate_del_keyboard(id)
    # edit :inline, msg, message, reply_markup: markup, bot: name, parse_mode: "HTML"
  end

  def handle({:command, "subscribe", %{chat: %{id: id}} = msg}, name, _) do
    answer msg, Daily.subscribe(id), bot: name, parse_mode: "HTML"
  end

  def handle({:command, "unsubscribe", %{chat: %{id: id}} = msg}, name, _) do
    answer msg, Daily.unsubscribe(id), bot: name, parse_mode: "HTML"
  end

  def handle({:command, "help", msg}, name, _) do
    answer msg, Server.help, bot: name, parse_mode: "HTML"
  end

  def handle({_, _, %{text: t}}, _, _) do
    Logger.error "Not handlers for message -> \"#{t}\""
  end

  def handle(m, _, _) do
    Logger.error "Unhandled message: #{inspect m}"
  end
end
