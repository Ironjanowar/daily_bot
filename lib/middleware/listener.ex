defmodule Middleware.Listener do
  require Logger

  def apply(%{update: %{message: m} = u} = s) do
    uid = Telex.Dsl.extract_id(u)
    username = Utils.extract_username(m)
    text = Utils.extract_text(m)

    Logger.info "#{username} [#{uid}] -> #{text}"
    {:ok, s}
  end
end
