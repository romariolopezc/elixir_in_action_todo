defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start_link(_) do
    IO.puts("Starting database server")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  def choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  def init(_) do
    {:ok, nil, {:continue, :init}}
  end

  def handle_call({:choose_worker, key}, _, workers) do
    worker_key = :erlang.phash2(key, map_size(workers))

    {:reply, Map.get(workers, worker_key), workers}
  end

  def handle_continue(:init, _) do
    File.mkdir_p!(@db_folder)
    {:noreply, start_workers()}
  end

  defp start_workers do
    for index <- 1..3, into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start_link(folder_name("worker_#{index}"))
      {index - 1, pid}
    end
  end

  defp folder_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end
