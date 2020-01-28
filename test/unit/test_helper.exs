ExUnit.start()

defmodule TestHelper do
  def dummy_child_spec() do
    %{
      id: :dummy,
      start: {Task, :start, [fn -> Process.sleep(60_000) end]}
    }
  end
end
