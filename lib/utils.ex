defmodule Utils do
  def create_inline_button(row) do
    row
    |> Enum.map(fn ops ->
      Map.merge(%Telex.Model.InlineKeyboardButton{}, Enum.into(ops, %{})) end)
  end

  def create_inline(data \\ [[]]) do
    data =
      data
      |> Enum.map(&Utils.create_inline_button/1)

    %Telex.Model.InlineKeyboardMarkup{inline_keyboard: data}
  end

  def generate_del_keyboard(id) do
    Server.redis_get_list(id)
    |> List.foldl([], fn x,acc -> [[[text: x, callback_data: x]] | acc] end)
    |> Enum.reverse
    |> (fn x -> [[[text: "Done", callback_data: "del:done"]]] ++ x end).()
    |> Enum.reverse
    |> Utils.create_inline
  end
end
