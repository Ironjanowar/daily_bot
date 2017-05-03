defmodule DailyBot do
  use Application
  def start, do: start(1, 1)

  def start(_, _) do
    import Supervisor.Spec

    rhost = Config.get(:daily_bot, :redis_host, "localhost")
    rport = Config.get_integer(:daily_bot, :redis_port, 6379)

    children = [
      worker(Redix, [[host: rhost, port: rport], [name: :redis, backoff_max: 5_000]]),
      supervisor(Telex, []),
      supervisor(DailyBot.Bot, [:updates, Application.get_env(:daily_bot, :token)]),
      worker(Server, [])
    ]

    opts = [strategy: :one_for_one, name: DailyBot]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        IO.puts "Starting"
        ok
      error ->
        IO.puts "Error"
        error
    end
  end
end
