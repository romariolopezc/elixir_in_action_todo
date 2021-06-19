defmodule Todo.Server do
  use GenServer

  def start(list_name) do
    GenServer.start(__MODULE__, list_name)
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
    {:ok, {list_name, Todo.Database.get(list_name) || Todo.List.new()}}
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
end

