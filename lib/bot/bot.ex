defmodule DailyBot.Bot do
  @bot :daily_bot
  def bot(), do: @bot

  use Telex.Bot, name: @bot
  use Telex.Dsl

  require Logger

  def handle({:command, "start", msg}, name, _) do
    answer msg, "_Hello there!_\nReady for the daily spam?", bot: name, parse_mode: "HTML"
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
