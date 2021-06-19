defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start do
    {:ok, worker1} = Todo.DatabaseWorker.start(folder_name("worker_1"))
    {:ok, worker2} = Todo.DatabaseWorker.start(folder_name("worker_2"))
    {:ok, worker3} = Todo.DatabaseWorker.start(folder_name("worker_3"))

    workers = %{0 => worker1, 1 => worker2, 2 => worker3}

    GenServer.start(__MODULE__, workers, name: __MODULE__)
  end

  def store(key, data) do
    worker_pid = choose_worker(key)

    Todo.DatabaseWorker.store(worker_pid, key, data)
  end

  def get(key) do
    worker_pid = choose_worker(key)

    Todo.DatabaseWorker.get(worker_pid, key)
  end

  def choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  def init(workers) do
    File.mkdir_p!(@db_folder)
    {:ok, workers}
  end

  def handle_call({:choose_worker, key}, _, workers) do
    worker_pid = Map.fetch!(workers, :erlang.phash2(key, map_size(workers)))

    {:reply, worker_pid, workers}
  end

  defp folder_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end

