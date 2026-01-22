# Chapter 7: Building a Concurrent System - Learning Exercises

## Chapter Summary

Chapter 7 demonstrates building production-scale concurrent systems by organizing multiple cooperating processes with Mix projects, where thousands of lightweight processes can efficiently handle independent tasks through message passing. The chapter shows how to structure code across multiple files following Elixir conventions, use process pools to limit concurrency for resources like disk I/O, and make architectural decisions about when operations should be synchronous calls versus asynchronous casts based on consistency requirements and back pressure needs. The TodoList system evolves from managing a single list to managing multiple lists concurrently with persistent storage, illustrating how to identify and address process bottlenecks through techniques like process bypassing, concurrent request handling, or controlled pooling.

---

## Concept Drills

### Drill 1: Mix Project Setup and Organization

**Objective:** Master Mix project structure and conventions.

**Task:** Create a properly structured Mix project:

```bash
# Create project
mix new my_app

# Project structure
my_app/
├── lib/
│   └── my_app/
│       ├── server.ex
│       ├── cache.ex
│       └── database/
│           └── worker.ex
├── test/
│   └── my_app/
│       ├── server_test.exs
│       └── cache_test.exs
├── mix.exs
└── README.md
```

**Naming Conventions:**
- Module: `MyApp.Database.Worker`
- File: `lib/my_app/database/worker.ex`
- Test: `test/my_app/database/worker_test.exs`

**Module Structure:**
```elixir
# lib/my_app.ex (top-level module)
defmodule MyApp do
  @moduledoc """
  Main application module.
  """
end

# lib/my_app/server.ex
defmodule MyApp.Server do
  @moduledoc """
  Server process for handling requests.
  """
  use GenServer

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Server Callbacks
  @impl GenServer
  def init(opts) do
    {:ok, %{}}
  end
end
```

**Commands:**
```bash
# Compile project
mix compile

# Run tests
mix test

# Start IEx with project loaded
iex -S mix

# Format code
mix format

# Check dependencies
mix deps

# Generate documentation
mix docs
```

---

### Drill 2: Managing Multiple Server Instances

**Objective:** Create a cache that manages multiple server processes.

**Task:** Build a UserCache that creates and tracks UserServer processes:

```elixir
defmodule UserServer do
  use GenServer

  # Client API
  def start_link(user_id) do
    GenServer.start_link(__MODULE__, user_id)
  end

  def get_profile(pid) do
    GenServer.call(pid, :get_profile)
  end

  def update_profile(pid, updates) do
    GenServer.cast(pid, {:update, updates})
  end

  # Server Callbacks
  @impl GenServer
  def init(user_id) do
    IO.puts("Starting UserServer for user #{user_id}")
    {:ok, %{user_id: user_id, name: "User#{user_id}", email: nil}}
  end

  @impl GenServer
  def handle_call(:get_profile, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:update, updates}, state) do
    {:noreply, Map.merge(state, updates)}
  end
end

defmodule UserCache do
  use GenServer

  # Client API
  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(user_id) do
    GenServer.call(__MODULE__, {:server_process, user_id})
  end

  # Server Callbacks
  @impl GenServer
  def init(_) do
    {:ok, %{}}  # Map of user_id => pid
  end

  @impl GenServer
  def handle_call({:server_process, user_id}, _from, servers) do
    case Map.fetch(servers, user_id) do
      {:ok, pid} ->
        # Server exists
        {:reply, pid, servers}

      :error ->
        # Start new server
        {:ok, pid} = UserServer.start_link(user_id)
        {:reply, pid, Map.put(servers, user_id, pid)}
    end
  end
end
```

**Test:**
```elixir
{:ok, _} = UserCache.start_link()

# Get server for user 1
pid1 = UserCache.server_process(1)

# Same call returns same server
^pid1 = UserCache.server_process(1)

# Different user gets different server
pid2 = UserCache.server_process(2)
assert pid1 != pid2

# Use the server
UserServer.update_profile(pid1, %{email: "user1@example.com"})
IO.inspect(UserServer.get_profile(pid1))
```

---

### Drill 3: Testing with ExUnit

**Objective:** Write comprehensive tests for GenServer processes.

**Task:** Test the UserCache and UserServer:

```elixir
# test/user_cache_test.exs
defmodule UserCacheTest do
  use ExUnit.Case

  setup do
    # Start cache for each test
    {:ok, cache} = UserCache.start_link()
    %{cache: cache}
  end

  test "returns same server for same user", %{cache: _cache} do
    pid1 = UserCache.server_process(1)
    pid2 = UserCache.server_process(1)

    assert pid1 == pid2
  end

  test "returns different servers for different users" do
    pid1 = UserCache.server_process(1)
    pid2 = UserCache.server_process(2)

    assert pid1 != pid2
  end

  test "server maintains state across calls" do
    pid = UserCache.server_process(1)

    UserServer.update_profile(pid, %{name: "Alice"})
    profile = UserServer.get_profile(pid)

    assert profile.name == "Alice"
  end

  test "creates multiple servers" do
    pids = Enum.map(1..10, fn id ->
      UserCache.server_process(id)
    end)

    # All different
    assert length(Enum.uniq(pids)) == 10
  end
end

# test/user_server_test.exs
defmodule UserServerTest do
  use ExUnit.Case

  test "initializes with user_id" do
    {:ok, pid} = UserServer.start_link(42)
    profile = UserServer.get_profile(pid)

    assert profile.user_id == 42
  end

  test "updates profile" do
    {:ok, pid} = UserServer.start_link(1)

    UserServer.update_profile(pid, %{name: "Bob", email: "bob@example.com"})

    profile = UserServer.get_profile(pid)
    assert profile.name == "Bob"
    assert profile.email == "bob@example.com"
  end

  test "pattern matching in assertions" do
    {:ok, pid} = UserServer.start_link(1)
    UserServer.update_profile(pid, %{name: "Charlie"})

    # Pattern match expected structure
    assert %{user_id: 1, name: "Charlie"} = UserServer.get_profile(pid)
  end
end
```

**Run tests:**
```bash
mix test
mix test test/user_cache_test.exs
mix test test/user_cache_test.exs:5  # Run specific line
mix test --trace  # See test names as they run
```

---

### Drill 4: Data Persistence with Erlang Terms

**Objective:** Persist and retrieve Elixir data structures.

**Task:** Implement simple file-based storage:

```elixir
defmodule SimpleStorage do
  @storage_dir "./data"

  def init do
    File.mkdir_p!(@storage_dir)
  end

  def store(key, data) do
    file_path = file_path(key)
    binary = :erlang.term_to_binary(data)
    File.write!(file_path, binary)
  end

  def get(key) do
    file_path = file_path(key)

    case File.read(file_path) do
      {:ok, binary} ->
        {:ok, :erlang.binary_to_term(binary)}

      {:error, :enoent} ->
        :not_found

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(key) do
    file_path(key)
    |> File.rm()
  end

  def list_keys do
    @storage_dir
    |> File.ls!()
    |> Enum.map(&String.to_atom/1)
  end

  defp file_path(key) do
    Path.join(@storage_dir, to_string(key))
  end
end
```

**Test:**
```elixir
SimpleStorage.init()

# Store complex data
data = %{
  user: "Alice",
  todos: [
    %{id: 1, title: "Buy milk", done: false},
    %{id: 2, title: "Call dentist", done: true}
  ],
  metadata: %{created_at: DateTime.utc_now()}
}

SimpleStorage.store(:alice_todos, data)

# Retrieve
{:ok, retrieved} = SimpleStorage.get(:alice_todos)
assert retrieved.user == "Alice"
assert length(retrieved.todos) == 2

# List keys
keys = SimpleStorage.list_keys()
assert :alice_todos in keys
```

---

### Drill 5: Process Bottleneck Analysis

**Objective:** Identify and measure process bottlenecks.

**Task:** Analyze performance of different approaches:

```elixir
defmodule BottleneckAnalysis do
  # Approach 1: Single process handles all work
  defmodule SingleProcess do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def work(n) do
      GenServer.call(__MODULE__, {:work, n})
    end

    @impl GenServer
    def init(_), do: {:ok, nil}

    @impl GenServer
    def handle_call({:work, n}, _from, state) do
      # Simulate work
      Process.sleep(n)
      {:reply, :done, state}
    end
  end

  # Approach 2: Work spawned to separate processes
  defmodule ConcurrentWork do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, nil, name: __MODULE__)
    end

    def work(n) do
      GenServer.call(__MODULE__, {:work, n}, :infinity)
    end

    @impl GenServer
    def init(_), do: {:ok, nil}

    @impl GenServer
    def handle_call({:work, n}, from, state) do
      spawn(fn ->
        Process.sleep(n)
        GenServer.reply(from, :done)
      end)

      {:noreply, state}
    end
  end

  # Benchmark
  def benchmark do
    work_units = List.duplicate(10, 100)  # 100 tasks, 10ms each

    # Single process
    SingleProcess.start_link()
    time1 = :timer.tc(fn ->
      Enum.each(work_units, fn n -> SingleProcess.work(n) end)
    end) |> elem(0) |> div(1000)

    IO.puts("Single process: #{time1}ms")

    # Concurrent
    ConcurrentWork.start_link()
    time2 = :timer.tc(fn ->
      tasks = Enum.map(work_units, fn n ->
        Task.async(fn -> ConcurrentWork.work(n) end)
      end)
      Task.await_many(tasks, :infinity)
    end) |> elem(0) |> div(1000)

    IO.puts("Concurrent: #{time2}ms")
    IO.puts("Speedup: #{Float.round(time1 / time2, 2)}x")
  end
end
```

---

### Drill 6: Cast vs Call Decision Making

**Objective:** Understand when to use cast vs call.

**Task:** Implement both patterns and understand trade-offs:

```elixir
defmodule CastVsCall do
  use GenServer

  defstruct total: 0, operations: []

  # Client API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Cast - fire and forget
  def add_async(value) do
    GenServer.cast(__MODULE__, {:add, value})
  end

  # Call - synchronous with confirmation
  def add_sync(value) do
    GenServer.call(__MODULE__, {:add, value})
  end

  def get_total do
    GenServer.call(__MODULE__, :get_total)
  end

  # Server Callbacks

  @impl GenServer
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_cast({:add, value}, state) do
    new_state = %{state |
      total: state.total + value,
      operations: [value | state.operations]
    }
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:add, value}, _from, state) do
    new_state = %{state |
      total: state.total + value,
      operations: [value | state.operations]
    }
    {:reply, :ok, new_state}
  end

  def handle_call(:get_total, _from, state) do
    {:reply, state.total, state}
  end
end
```

**Compare behavior:**
```elixir
{:ok, _} = CastVsCall.start_link()

# Cast - immediate return, no guarantee
CastVsCall.add_async(10)
CastVsCall.add_async(20)

# Might not be processed yet!
IO.inspect(CastVsCall.get_total())  # Could be 0, 10, or 30

# Call - blocks until processed
CastVsCall.add_sync(30)

# Guaranteed to be included
IO.inspect(CastVsCall.get_total())  # Will be at least 30
```

**Decision Matrix:**

| Characteristic | Cast | Call |
|---------------|------|------|
| Returns immediately | ✅ | ❌ |
| Confirmation of success | ❌ | ✅ |
| Back pressure | ❌ | ✅ |
| Caller blocked | ❌ | ✅ |
| Best for | Fire-and-forget, performance critical | Need response, consistency critical |

---

### Drill 7: Process Pooling

**Objective:** Implement a simple worker pool.

**Task:** Create a pool of worker processes:

```elixir
defmodule Worker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def work(pid, task) do
    GenServer.call(pid, {:work, task})
  end

  @impl GenServer
  def init(id) do
    {:ok, %{id: id, tasks_completed: 0}}
  end

  @impl GenServer
  def handle_call({:work, task}, _from, state) do
    # Simulate work
    result = task.()

    new_state = %{state | tasks_completed: state.tasks_completed + 1}
    {:reply, {:ok, result, state.id}, new_state}
  end
end

defmodule WorkerPool do
  use GenServer

  def start_link(pool_size) do
    GenServer.start_link(__MODULE__, pool_size, name: __MODULE__)
  end

  def execute(task) do
    GenServer.call(__MODULE__, {:execute, task}, :infinity)
  end

  @impl GenServer
  def init(pool_size) do
    # Start worker processes
    workers = Enum.map(1..pool_size, fn id ->
      {:ok, pid} = Worker.start_link(id)
      pid
    end)

    {:ok, %{workers: workers, current: 0}}
  end

  @impl GenServer
  def handle_call({:execute, task}, _from, state) do
    # Round-robin selection
    worker = Enum.at(state.workers, state.current)
    result = Worker.work(worker, task)

    # Update current index
    next = rem(state.current + 1, length(state.workers))

    {:reply, result, %{state | current: next}}
  end
end
```

**Test:**
```elixir
{:ok, _} = WorkerPool.start_link(3)

# Execute tasks
tasks = Enum.map(1..10, fn i ->
  Task.async(fn ->
    WorkerPool.execute(fn ->
      Process.sleep(100)
      i * 2
    end)
  end)
end)

results = Task.await_many(tasks, :infinity)
IO.inspect(results)
```

---

## Integration Exercises

### Exercise 1: Multi-User Todo System with Cache

**Objective:** Build complete todo system with multiple lists.

**Concepts Reinforced:**
- GenServer (Chapter 6)
- TodoList (Chapter 4)
- Process management (Chapter 5)
- Cache pattern (Chapter 7)

**Task:** Complete the multi-user todo system:

```elixir
# lib/todo/server.ex
defmodule Todo.Server do
  use GenServer

  def start_link(list_name) do
    GenServer.start_link(__MODULE__, list_name)
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def update_entry(pid, entry_id, updater_fn) do
    GenServer.cast(pid, {:update, entry_id, updater_fn})
  end

  @impl GenServer
  def init(list_name) do
    IO.puts("Starting todo server for: #{list_name}")
    {:ok, {list_name, Todo.List.new()}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, list}) do
    new_list = Todo.List.add_entry(list, entry)
    {:noreply, {name, new_list}}
  end

  def handle_cast({:update, entry_id, updater_fn}, {name, list}) do
    new_list = Todo.List.update_entry(list, entry_id, updater_fn)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end
end

# lib/todo/cache.ex
defmodule Todo.Cache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def server_process(list_name) do
    GenServer.call(__MODULE__, {:server_process, list_name})
  end

  def list_names do
    GenServer.call(__MODULE__, :list_names)
  end

  @impl GenServer
  def init(_) do
    IO.puts("Starting todo cache")
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:server_process, list_name}, _from, servers) do
    case Map.fetch(servers, list_name) do
      {:ok, pid} ->
        {:reply, pid, servers}

      :error ->
        {:ok, pid} = Todo.Server.start_link(list_name)
        {:reply, pid, Map.put(servers, list_name, pid)}
    end
  end

  def handle_call(:list_names, _from, servers) do
    {:reply, Map.keys(servers), servers}
  end
end
```

**Test:**
```elixir
# Start cache
{:ok, _} = Todo.Cache.start_link()

# Get servers for different lists
alice_list = Todo.Cache.server_process("Alice")
bob_list = Todo.Cache.server_process("Bob")

# Add entries
Todo.Server.add_entry(alice_list, %{
  date: ~D[2024-01-22],
  title: "Dentist appointment"
})

Todo.Server.add_entry(bob_list, %{
  date: ~D[2024-01-22],
  title: "Team meeting"
})

# Query
alice_todos = Todo.Server.entries(alice_list, ~D[2024-01-22])
bob_todos = Todo.Server.entries(bob_list, ~D[2024-01-22])

# Different lists managed independently
assert length(alice_todos) == 1
assert length(bob_todos) == 1
assert hd(alice_todos).title != hd(bob_todos).title

# List all active lists
names = Todo.Cache.list_names()
assert "Alice" in names
assert "Bob" in names
```

---

### Exercise 2: Persistent Todo System

**Objective:** Add data persistence to todo system.

**Concepts Reinforced:**
- File I/O (Chapter 7)
- Erlang term format (Chapter 7)
- GenServer (Chapter 6)
- Two-phase initialization (Chapter 7)

**Task:** Add database layer:

```elixir
defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)
    IO.puts("Database ready: #{@db_folder}")
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    spawn(fn ->
      file_path = file_path(key)
      binary = :erlang.term_to_binary(data)
      File.write!(file_path, binary)
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, from, state) do
    spawn(fn ->
      result = case File.read(file_path(key)) do
        {:ok, binary} -> :erlang.binary_to_term(binary)
        {:error, :enoent} -> nil
      end

      GenServer.reply(from, result)
    end)

    {:noreply, state}
  end

  defp file_path(key) do
    Path.join(@db_folder, to_string(key))
  end
end

# Update Todo.Server to use database
defmodule Todo.Server do
  use GenServer

  def start_link(list_name) do
    GenServer.start_link(__MODULE__, list_name)
  end

  # ... (interface functions same as before)

  @impl GenServer
  def init(list_name) do
    IO.puts("Starting todo server for: #{list_name}")
    {:ok, {list_name, nil}, {:continue, :load_data}}
  end

  @impl GenServer
  def handle_continue(:load_data, {list_name, nil}) do
    list = case Todo.Database.get(list_name) do
      nil -> Todo.List.new()
      data -> data
    end

    {:noreply, {list_name, list}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, list}) do
    new_list = Todo.List.add_entry(list, entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  # ... (other handlers save to database)
end

# Update Cache to start database
defmodule Todo.Cache do
  use GenServer

  @impl GenServer
  def init(_) do
    Todo.Database.start_link()
    {:ok, %{}}
  end

  # ... (rest same as before)
end
```

**Test persistence:**
```elixir
# Session 1
{:ok, _} = Todo.Cache.start_link()
alice = Todo.Cache.server_process("Alice")
Todo.Server.add_entry(alice, %{date: ~D[2024-01-22], title: "Buy milk"})

# Restart system (close iex and start again)

# Session 2
{:ok, _} = Todo.Cache.start_link()
alice = Todo.Cache.server_process("Alice")
entries = Todo.Server.entries(alice, ~D[2024-01-22])

# Data persisted!
assert length(entries) == 1
assert hd(entries).title == "Buy milk"
```

---

### Exercise 3: Worker Pool for Database Operations

**Objective:** Implement pooling for database workers.

**Concepts Reinforced:**
- Process pooling (Chapter 7)
- Hash-based routing (Chapter 7)
- GenServer (Chapter 6)
- Concurrent operations (Chapter 5)

**Task:** Create database with worker pool:

```elixir
defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(db_folder) do
    GenServer.start_link(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.cast(pid, {:store, key, data})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  @impl GenServer
  def init(db_folder) do
    {:ok, db_folder}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, db_folder) do
    file_path = Path.join(db_folder, to_string(key))
    binary = :erlang.term_to_binary(data)
    File.write!(file_path, binary)

    IO.puts("#{inspect(self())}: stored #{key}")
    {:noreply, db_folder}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, db_folder) do
    file_path = Path.join(db_folder, to_string(key))

    data = case File.read(file_path) do
      {:ok, binary} -> :erlang.binary_to_term(binary)
      {:error, :enoent} -> nil
    end

    IO.puts("#{inspect(self())}: retrieved #{key}")
    {:reply, data, db_folder}
  end
end

defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"
  @pool_size 3

  def start_link do
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

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)

    # Start worker pool
    workers = Enum.reduce(0..(@pool_size - 1), %{}, fn index, acc ->
      {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder)
      Map.put(acc, index, pid)
    end)

    IO.puts("Database started with #{@pool_size} workers")
    {:ok, workers}
  end

  @impl GenServer
  def handle_call({:choose_worker, key}, _from, workers) do
    worker_index = :erlang.phash2(key, @pool_size)
    {:reply, Map.get(workers, worker_index), workers}
  end

  defp choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end
end
```

**Test hash-based routing:**
```elixir
{:ok, _} = Todo.Database.start_link()

# Store keys - same key always goes to same worker
Todo.Database.store("alice", %{name: "Alice"})
Todo.Database.store("bob", %{name: "Bob"})
Todo.Database.store("alice", %{name: "Alice", updated: true})

# Observe in output: alice always handled by same worker
```

---

## Capstone Project: Distributed Session Store

### Project Description

Build a production-ready distributed session store with multiple features: session management, expiration, persistence, statistics, and worker pooling.

### Requirements

#### 1. Session Server

```elixir
defmodule SessionStore.Session do
  use GenServer

  defstruct [
    :session_id,
    :data,
    :created_at,
    :last_accessed,
    :ttl
  ]

  def start_link(session_id, ttl \\ 3600) do
    GenServer.start_link(__MODULE__, {session_id, ttl})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def put(pid, key, value) do
    GenServer.cast(pid, {:put, key, value})
  end

  def all_data(pid) do
    GenServer.call(pid, :all_data)
  end

  def touch(pid) do
    GenServer.cast(pid, :touch)
  end

  @impl GenServer
  def init({session_id, ttl}) do
    state = %__MODULE__{
      session_id: session_id,
      data: %{},
      created_at: DateTime.utc_now(),
      last_accessed: DateTime.utc_now(),
      ttl: ttl
    }

    # Schedule expiration check
    schedule_expiration_check(ttl)

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state.data, key)
    new_state = %{state | last_accessed: DateTime.utc_now()}
    {:reply, value, new_state}
  end

  def handle_call(:all_data, _from, state) do
    {:reply, state.data, state}
  end

  @impl GenServer
  def handle_cast({:put, key, value}, state) do
    new_data = Map.put(state.data, key, value)
    new_state = %{state |
      data: new_data,
      last_accessed: DateTime.utc_now()
    }
    {:noreply, new_state}
  end

  def handle_cast(:touch, state) do
    {:noreply, %{state | last_accessed: DateTime.utc_now()}}
  end

  @impl GenServer
  def handle_info(:check_expiration, state) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, state.last_accessed)

    if elapsed >= state.ttl do
      {:stop, :normal, state}
    else
      schedule_expiration_check(state.ttl - elapsed)
      {:noreply, state}
    end
  end

  defp schedule_expiration_check(seconds) do
    Process.send_after(self(), :check_expiration, seconds * 1000)
  end
end
```

#### 2. Session Cache

```elixir
defmodule SessionStore.Cache do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def create_session(session_id, ttl \\ 3600) do
    GenServer.call(__MODULE__, {:create_session, session_id, ttl})
  end

  def get_session(session_id) do
    GenServer.call(__MODULE__, {:get_session, session_id})
  end

  def delete_session(session_id) do
    GenServer.call(__MODULE__, {:delete_session, session_id})
  end

  def active_sessions do
    GenServer.call(__MODULE__, :active_sessions)
  end

  @impl GenServer
  def init(_) do
    SessionStore.Database.start_link()
    {:ok, %{sessions: %{}, monitors: %{}}}
  end

  @impl GenServer
  def handle_call({:create_session, session_id, ttl}, _from, state) do
    case Map.fetch(state.sessions, session_id) do
      {:ok, pid} ->
        {:reply, {:ok, pid}, state}

      :error ->
        {:ok, pid} = SessionStore.Session.start_link(session_id, ttl)
        ref = Process.monitor(pid)

        new_state = %{state |
          sessions: Map.put(state.sessions, session_id, pid),
          monitors: Map.put(state.monitors, ref, session_id)
        }

        {:reply, {:ok, pid}, new_state}
    end
  end

  def handle_call({:get_session, session_id}, _from, state) do
    result = case Map.fetch(state.sessions, session_id) do
      {:ok, pid} -> {:ok, pid}
      :error -> :not_found
    end

    {:reply, result, state}
  end

  def handle_call({:delete_session, session_id}, _from, state) do
    case Map.fetch(state.sessions, session_id) do
      {:ok, pid} ->
        Process.exit(pid, :shutdown)
        {:reply, :ok, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:active_sessions, _from, state) do
    {:reply, Map.keys(state.sessions), state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {session_id, monitors} = Map.pop(state.monitors, ref)
    sessions = Map.delete(state.sessions, session_id)

    {:noreply, %{state | sessions: sessions, monitors: monitors}}
  end
end
```

#### 3. Persistent Storage with Pooling

```elixir
defmodule SessionStore.DatabaseWorker do
  use GenServer

  def start_link({index, db_folder}) do
    GenServer.start_link(__MODULE__, {index, db_folder})
  end

  def save(pid, session_id, data) do
    GenServer.cast(pid, {:save, session_id, data})
  end

  def load(pid, session_id) do
    GenServer.call(pid, {:load, session_id})
  end

  @impl GenServer
  def init({index, db_folder}) do
    IO.puts("Worker #{index} started")
    {:ok, %{index: index, folder: db_folder}}
  end

  @impl GenServer
  def handle_cast({:save, session_id, data}, state) do
    file = Path.join(state.folder, "#{session_id}.session")
    binary = :erlang.term_to_binary(data)
    File.write!(file, binary)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:load, session_id}, _from, state) do
    file = Path.join(state.folder, "#{session_id}.session")

    data = case File.read(file) do
      {:ok, binary} -> {:ok, :erlang.binary_to_term(binary)}
      {:error, :enoent} -> :not_found
    end

    {:reply, data, state}
  end
end

defmodule SessionStore.Database do
  use GenServer

  @db_folder "./sessions"
  @pool_size 3

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def save(session_id, data) do
    worker = choose_worker(session_id)
    SessionStore.DatabaseWorker.save(worker, session_id, data)
  end

  def load(session_id) do
    worker = choose_worker(session_id)
    SessionStore.DatabaseWorker.load(worker, session_id)
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p!(@db_folder)

    workers = for index <- 0..(@pool_size - 1), into: %{} do
      {:ok, pid} = SessionStore.DatabaseWorker.start_link({index, @db_folder})
      {index, pid}
    end

    {:ok, workers}
  end

  @impl GenServer
  def handle_call({:choose_worker, session_id}, _from, workers) do
    index = :erlang.phash2(session_id, @pool_size)
    {:reply, Map.get(workers, index), workers}
  end

  defp choose_worker(session_id) do
    GenServer.call(__MODULE__, {:choose_worker, session_id})
  end
end
```

#### 4. Statistics and Monitoring

```elixir
defmodule SessionStore.Stats do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def record_create do
    GenServer.cast(__MODULE__, :create)
  end

  def record_access do
    GenServer.cast(__MODULE__, :access)
  end

  def record_delete do
    GenServer.cast(__MODULE__, :delete)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl GenServer
  def init(_) do
    {:ok, %{creates: 0, accesses: 0, deletes: 0, start_time: DateTime.utc_now()}}
  end

  @impl GenServer
  def handle_cast(:create, state) do
    {:noreply, %{state | creates: state.creates + 1}}
  end

  def handle_cast(:access, state) do
    {:noreply, %{state | accesses: state.accesses + 1}}
  end

  def handle_cast(:delete, state) do
    {:noreply, %{state | deletes: state.deletes + 1}}
  end

  @impl GenServer
  def handle_call(:get_stats, _from, state) do
    uptime = DateTime.diff(DateTime.utc_now(), state.start_time)
    stats = Map.put(state, :uptime_seconds, uptime)
    {:reply, stats, state}
  end
end
```

### Deliverables

1. Complete session store with cache, persistence, and pooling
2. Comprehensive test suite
3. Load testing script
4. Performance analysis

### Bonus Challenges

1. **Session clustering:** Distribute sessions across nodes
2. **Backup strategy:** Periodic snapshots
3. **Compression:** Compress large session data
4. **Analytics:** Track popular data keys
5. **Admin interface:** Web dashboard

### Evaluation Criteria

**Architecture (30 points)**
- Multi-process design (10 pts)
- Cache management (10 pts)
- Worker pooling (10 pts)

**Persistence (25 points)**
- Save/load works correctly (10 pts)
- Hash-based routing (10 pts)
- Error handling (5 pts)

**Features (25 points)**
- Session expiration (10 pts)
- Statistics tracking (10 pts)
- Clean API (5 pts)

**Testing (20 points)**
- Comprehensive tests (15 pts)
- Performance testing (5 pts)

---

## Success Checklist

Before moving to Chapter 9, ensure you can:

- [ ] Create and organize Mix projects
- [ ] Follow Elixir file naming conventions
- [ ] Write tests with ExUnit
- [ ] Manage multiple server process instances
- [ ] Implement cache pattern for process management
- [ ] Persist data with Erlang term format
- [ ] Identify process bottlenecks
- [ ] Decide between cast and call
- [ ] Implement worker pooling
- [ ] Use hash-based routing for consistent assignment
- [ ] Perform two-phase initialization with handle_continue
- [ ] Analyze process dependencies
- [ ] Measure and optimize performance

---

## Looking Ahead

Chapter 9 covers Supervision Trees, building on the multi-process architecture from Chapter 7:
- Hierarchical supervision structures
- Multiple supervision strategies
- Dynamic supervisors for runtime children
- Building fault-tolerant systems at scale

The concurrent architecture patterns from Chapter 7 become the foundation for production-grade fault-tolerant systems!
