defmodule Todo.Server do
  use GenServer, restart: :temporary

  def start_link(list_name) do
    IO.puts("Starting to-do server for #{list_name}")

    GenServer.start_link(__MODULE__, list_name, name: global_name(list_name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def all_entries(todo_server) do
    GenServer.call(todo_server, :all_entries)
  end

  @impl GenServer
  def init(list_name) do
    {:ok, nil, {:continue, {:init, list_name}}}
  end

  @impl GenServer
  def handle_cast({:add_entry, new_entry}, {list_name, todo_list}) do
    new_state = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(list_name, new_state)
    {:noreply, {list_name, new_state}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {_, todo_list} = state) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      state
    }
  end

  @impl GenServer
  def handle_call(:all_entries, _, {_, todo_list} = state) do
    {
      :reply,
      Todo.List.all_entries(todo_list),
      state
    }
  end

  @impl GenServer
  def handle_continue({:init, list_name}, _) do
    todo_list = Todo.Database.get(list_name) || Todo.List.new()
    {:noreply, {list_name, todo_list}}
  end

  defp global_name(list_name) do
    {:global, {__MODULE__, list_name}}
  end

  def whereis(list_name) do
    case :global.whereis_name({__MODULE__, list_name}) do
      :undefined -> nil
      pid -> pid
    end
  end
end
