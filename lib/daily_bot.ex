defmodule DailyBot do
  use Application
  def start, do: start(1, 1)

  require Logger

  def start(_, _) do
    import Supervisor.Spec

    rhost = Telex.Config.get(:daily_bot, :redis_host, "localhost")
    rport = Telex.Config.get_integer(:daily_bot, :redis_port, 6379)

    token = Telex.Config.get(:daily_bot, :token)

    children = [
      worker(Redix, [[host: rhost, port: rport], [name: :redis, backoff_max: 5_000]]),
      supervisor(Telex, []),
      supervisor(DailyBot.Bot, [:polling, token]),
      worker(Server, []),
      worker(Daily, []),
      worker(Middleware.ChatStep, []),
      worker(DailyBot.Scheduler, [])
    ]

    opts = [strategy: :one_for_one, name: DailyBot]
    case Supervisor.start_link(children, opts) do
      {:ok, _} = ok ->
        Logger.info "Starting DailyBot"
        ok
      error ->
        Logger.error "Error starting DailyBot"
        error
    end
  end
end
