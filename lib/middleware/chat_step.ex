defmodule Middleware.ChatStep do
  require Logger
  def start_link do
    Agent.start_link(fn -> [] end, name: :chat_step)
  end

  def save_cid(cid) do
    Agent.update(:chat_step, fn state -> [cid | state] end)
  end

  def remove_cid(cid) do
    Agent.update(:chat_step, fn state -> List.delete(state, cid) end)
  end

  def get_cids() do
    Agent.get(:chat_step, &(&1))
  end

  def apply(%{update: %{message: %{chat: %{id: cid}, text: t}}} = s) do
    Logger.info "Checking if message '#{t}' is an expected answer"
    if cid in get_cids() do
      {:ok, Map.put(s, :is_answer, true)}
    else
      {:ok, Map.put(s, :is_answer, false)}
    end
  end
  def apply(s) do
    Logger.info "Not an expected answer"
    {:ok, s}
  end
end
