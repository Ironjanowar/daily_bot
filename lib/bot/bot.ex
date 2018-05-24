defmodule DailyBot.Bot do
  @bot :daily_bot

  use ExGram.Bot,
    name: @bot,
    middlewares: [
      Middleware.Listener,
      Middleware.ChatStep
    ]

  require Logger

  def bot(), do: @bot

  def handle({:command, "start", _msg}, _name, _) do
    answer("<b>Hello there!</b>\nReady for the daily spam?", parse_mode: "HTML")
  end

  def handle({:command, "todo", %{chat: %{id: id}} = msg}, name, _) do
    case Server.get_list(id) do
      {:empty, message} ->
        answer(message)

      {:ok, message} ->
        markup = Utils.generate_hide_and_del_button()
        answer(message, parse_mode: "HTML", disable_web_page_preview: true, reply_markup: markup)
    end
  end

  def handle({:command, "add", %{text: "", chat: %{id: cid}, message_id: mid} = msg}, name, _) do
    Middleware.ChatStep.save_cid(cid)

    answer(
      msg,
      "What do you want to add?",
      bot: name,
      reply_markup: %ExGram.Model.ForceReply{force_reply: true, selective: true},
      reply_to_message_id: mid
    )
  end

  def handle({:command, "add", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer(msg, Server.add_to_list(id, t), bot: name, parse_mode: "HTML")
  end

  # Add's second step
  def handle(_, name, %{is_answer: true, update: %{message: %{text: t, chat: %{id: id}}} = msg}) do
    Middleware.ChatStep.remove_cid(id)
    Logger.info("Add's second step for #{id}, answered: #{t}")

    answer(
      msg,
      Server.add_to_list(id, t),
      bot: name,
      parse_mode: "HTML",
      reply_markup: %ExGram.Model.ReplyKeyboardRemove{remove_keyboard: true}
    )
  end

  def handle({:command, "forcedel", %{text: t, chat: %{id: id}} = msg}, name, _) do
    answer(msg, Server.del_from_list(id, t), bot: name, parse_mode: "HTML")
  end

  def handle({:command, "del", %{chat: %{id: id}} = msg}, name, _) do
    markup = Utils.generate_del_keyboard(id)
    answer(msg, "Select any element that you want to remove", reply_markup: markup, bot: name)
  end

  def handle({:callback_query, %{data: "del:done"} = msg}, name, _) do
    message = "Enought removing things!"
    markup = Utils.generate_show_button()
    edit(:inline, msg, message, bot: name, parse_mode: "HTML", reply_markup: markup)
  end

  def handle(
        {:callback_query, %{message: %{chat: %{id: id}}, data: "del:elem:" <> elem} = msg},
        name,
        _
      ) do
    if Server.naisdel_from_list(elem) do
      markup = Utils.generate_del_keyboard(id)

      case length(markup.inline_keyboard) do
        1 ->
          show_list_markup = Utils.generate_show_button()
          message = "Enought removing things!"

          edit(
            :inline,
            msg,
            message,
            bot: name,
            parse_mode: "HTML",
            reply_markup: show_list_markup
          )

        _ ->
          edit(
            :inline,
            msg,
            "<b>Element removed!</b>\n\nSelect any element that you want to remove",
            reply_markup: markup,
            parse_mode: "HTML",
            bot: name
          )
      end
    else
      Logger.error("Callback query matching error #{elem} (WTF NIGGI)")
    end
  end

  def handle({:command, "subscribe", %{chat: %{id: id}} = msg}, name, _) do
    answer(msg, Daily.subscribe(id), bot: name, parse_mode: "HTML")
  end

  def handle({:command, "unsubscribe", %{chat: %{id: id}} = msg}, name, _) do
    answer(msg, Daily.unsubscribe(id), bot: name, parse_mode: "HTML")
  end

  def handle({:command, "help", msg}, name, _) do
    answer(msg, Server.help(), bot: name, parse_mode: "HTML")
  end

  def handle({:command, "donate", msg}, name, _) do
    markup = Utils.generate_donation_button()
    answer(msg, Utils.donation_text(), bot: name, parse_mode: "HTML", reply_markup: markup)
  end

  def handle({:callback_query, %{data: "action:hide"} = msg}, name, _) do
    markup = Utils.generate_show_button()
    edit(:inline, msg, "Hided TODO list 🙈", bot: name, reply_markup: markup)
  end

  def handle(
        {:callback_query, %{data: "action:show", message: %{chat: %{id: id}}} = msg},
        name,
        _
      ) do
    case Server.get_list(id) do
      {:empty, message} ->
        edit(:inline, msg, message, bot: name)

      {:ok, message} ->
        markup = Utils.generate_hide_and_del_button()

        edit(
          :inline,
          msg,
          message,
          parse_mode: "HTML",
          disable_web_page_preview: true,
          reply_markup: markup,
          bot: name
        )
    end
  end

  def handle(
        {:callback_query, %{data: "action:delete:elements", message: %{chat: %{id: id}}} = msg},
        name,
        _
      ) do
    markup = Utils.generate_del_keyboard(id)

    edit(
      :inline,
      msg,
      "Select any element that you want to remove",
      reply_markup: markup,
      bot: name
    )
  end

  def handle({_, _, %{text: t}}, _, _) do
    Logger.error("Not handlers for message -> \"#{t}\"")
  end

  def handle(m, _, _) do
    Logger.error("Unhandled message: #{inspect(m)}")
  end
end
