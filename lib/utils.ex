defmodule Utils do
  require Logger

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

  def hash_md5(text) do
    :crypto.hash(:md5, text) |> Base.encode16()
  end

  def get_from_hash(hash) do
    case String.split(hash, ":") do
      [id, _] ->
        case Redix.command(:redis, ~w(GET #{hash})) do
          {:ok, nil} -> :error
          {:ok, elem} -> {:ok, id, URI.decode(elem)}
        end
      _ -> :error
    end
    # [id, _] = String.split(hash, ":")
    # {:ok, text} = Redix.command(:redis, ~w(GET #{hash}))
    # {id, text}
  end

  def save_hash(id, text) do
    hash = Utils.hash_md5(text)
    Logger.info "Saving hash: #{hash} for #{id}"
    Redix.command(:redis, ~w(SET #{id}:#{hash} #{URI.encode(text)}))
  end

  def del_hash_from_redis(key) do
    Logger.info "Deleting hash: #{key}"
    Redix.command(:redis, ~w(DEL #{key}))
  end

  def generate_del_keyboard(id) do
    Logger.info "Generating del keyboard for #{id}"

    Server.redis_get_list(id)
    |> List.foldl([], fn x,acc -> [[[text: x, callback_data: "del:elem:#{id}:#{hash_md5(x)}"]] | acc] end)
    |> (fn x -> x ++ [[[text: "Done", callback_data: "del:done"]]] end).()
    |> Utils.create_inline
  end

  def donation_text() do
    "Hi! If you enjoy this bot and want to donate a beer, click the button below.\nThank you so much for using this bot ❤️"
  end

  def generate_donation_button() do
    Utils.create_inline [[[text: "Donate", url: "paypal.me/ironjanowar"]]]
  end

  def extract_username(%{from: %{username: username}}), do: username

  def extract_text(%{text: text}) when not is_nil(text), do: text
  def extract_text(_), do: "[Message is not a text]"
end
