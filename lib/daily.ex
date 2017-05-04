defmodule Daily do
  use GenServer

  require Logger

  def start_link do
    GenServer.start_link __MODULE__, :ok, [name: :daily]
  end

  def init(:ok) do
    case Redix.command(:redis, ~w()) do
      [] -> ""
      ids -> Enum.map(ids, fn id -> Process.send_after(self(), {:spam, id}, millis_to_next_day()) end)
    end

    {:ok, []}
  end

  defp millis_to_next_day() do
    now = Timex.now("Europe/Madrid")
    tomorrow = Timex.shift(Timex.beginning_of_day(now), days: 1, hours: 9)
    Timex.diff(tomorrow, now, :milliseconds)
  end

  def subscribe(id) do
    Redix.command(:redis, ~w(LPUSH daily #{id}))
  end

  def unsubscribe(id) do
    Redix.command(:redis, ~w(LREM daily 1 #{id}))
  end

  def handle_info({:spam, id}, state) do
    tomorrow = 86_400_000 # 24 hours
    Telex.send_message(id, Server.get_list(id), bot: :daily_bot)
    Process.send_after(self(), {:spam, id}, tomorrow)
    {:noreply, state}
  end
end
