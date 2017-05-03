defmodule DailyBot.Bot do
  @bot :daily_bot
  def bot(), do: @bot

  use Telex.Bot, name: @bot
  use Telex.Dsl

  def handle({:command, "start", msg}, name, _) do
    answer msg, "_Hello there!_\nReady for the daily spam?\nTomorrow at 9:00am I will send you your *TODO* list.", bot: name, parse_mode: "Markdown"
  end

  def handle({:command, "todo", %{chat: %{id: id}}  =msg}, name, _) do
    answer msg, Server.get_list(id), bot: name, parse_mode: "Markdown"
  end

  def handle({:command, "add", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer msg, Server.add_to_list(id, t), bot: name, parse_mode: "Markdown"
  end

  def handle({:command, "del", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer msg, Server.del_from_list(id, t), bot: name, parse_mode: "Markdown"
  end

  # Listener
  def handle({_, _, %{text: t, from: %{username: user}}}, _) when not is_nil(user) do
    [:hotpink, "[LISTENER] @#{user} -> #{t}"]
    |> Bunt.puts
  end

  def handle({_, _, %{text: t, from: %{first_name: user}}}, _) do
    [:hotpink, "[LISTENER] @#{user} -> #{t}"]
    |> Bunt.puts
  end
end
