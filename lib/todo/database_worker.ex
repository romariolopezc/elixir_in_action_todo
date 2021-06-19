defmodule Todo.DatabaseWorker do
  use GenServer

  def start(dir_name) do
    GenServer.start(__MODULE__, dir_name)
  end

  def store(worker_pid, key, data) do
    GenServer.cast(worker_pid, {:store, key, data})
  end

  def get(worker_pid, key) do
    GenServer.call(worker_pid, {:get, key})
  end

  def init(dir_name) do
    File.mkdir_p!(dir_name)

    {:ok, dir_name}
  end

  def handle_cast({:store, key, data}, dir_name) do
    dir_name
    |> file_name(key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, dir_name}
  end

  def handle_call({:get, key}, _, dir_name) do
    data =
      case File.read(file_name(dir_name, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, dir_name}
  end

  defp file_name(dir_name, key) do
    Path.join(dir_name, to_string(key))
  end
end
