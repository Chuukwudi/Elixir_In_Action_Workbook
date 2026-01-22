# Chapter 9: Isolating Error Effects - Learning Exercises

## Chapter Summary

Chapter 9 explores how to build fault-tolerant systems through fine-grained supervision trees that isolate error effects. By strategically organizing processes under supervisors, using the Registry module for process discovery, and leveraging DynamicSupervisor for on-demand process creation, you can confine errors to small parts of the system while maintaining overall availability. The chapter demonstrates how proper supervision tree design, combined with restart strategies and the "let it crash" philosophy, enables building self-healing systems where failures in one component don't cascade throughout the entire application.

---

## Concept Drills

### Drill 1: Understanding Process Registries

**Objective:** Master the Registry module for process discovery.

**Task:** Explore how Registry enables finding processes by complex keys:

```elixir
# Start a registry
Registry.start_link(name: :my_registry, keys: :unique)

# Register processes with complex keys
defmodule Worker do
  def start_link(id) do
    spawn(fn ->
      Registry.register(:my_registry, {:worker, id}, %{started_at: System.system_time()})
      loop()
    end)
  end

  defp loop do
    receive do
      {:work, data} ->
        IO.puts("Worker processing: #{data}")
        loop()
      :stop -> :ok
    end
  end
end

# Start workers
w1 = Worker.start_link(1)
w2 = Worker.start_link(2)
w3 = Worker.start_link(3)

# Look them up
[{pid, metadata}] = Registry.lookup(:my_registry, {:worker, 2})
send(pid, {:work, "important task"})
```

**Exercises:**
1. Create a registry and register 5 processes with keys like `{:task, task_id}`
2. Look up a process by its key and send it a message
3. What happens when you try to register two processes with the same key in a unique registry?
4. Terminate a registered process and verify Registry automatically removes it
5. Create a duplicate registry and register multiple processes under the same key

**Expected Outcomes:**
- Unique registry: only one process per key
- Duplicate registry: multiple processes can share a key
- Terminated processes are automatically deregistered
- `Registry.lookup/2` returns `[]` for non-existent keys

---

### Drill 2: Via Tuples for Process Registration

**Objective:** Use via tuples to register OTP processes.

**Task:** Implement a registered GenServer using via tuples:

```elixir
defmodule WorkerRegistry do
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end

defmodule TaskWorker do
  use GenServer

  def start_link(worker_id) do
    GenServer.start_link(
      __MODULE__,
      worker_id,
      name: WorkerRegistry.via_tuple({__MODULE__, worker_id})
    )
  end

  def get_status(worker_id) do
    GenServer.call(
      WorkerRegistry.via_tuple({__MODULE__, worker_id}),
      :status
    )
  end

  def process_task(worker_id, task) do
    GenServer.cast(
      WorkerRegistry.via_tuple({__MODULE__, worker_id}),
      {:task, task}
    )
  end

  ## Callbacks

  @impl GenServer
  def init(worker_id) do
    {:ok, %{id: worker_id, tasks_completed: 0, current_task: nil}}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:task, task}, state) do
    IO.puts("Worker #{state.id} processing: #{task}")
    new_state = %{state |
      tasks_completed: state.tasks_completed + 1,
      current_task: task
    }
    {:noreply, new_state}
  end
end
```

**Exercises:**
1. Start the registry and create 3 task workers
2. Send tasks to workers using their IDs (no PIDs needed)
3. Query worker status using only the ID
4. Kill a worker and restart it - verify you can still reach it by ID
5. Try to start two workers with the same ID - what happens?

**Success Criteria:**
- Workers discoverable by ID without storing PIDs
- Via tuple format: `{:via, Registry, {registry_name, key}}`
- After restart, same ID reaches new process
- Duplicate registration fails gracefully

---

### Drill 3: Supervision Tree Organization

**Objective:** Understand how to structure supervision trees for error isolation.

**Task:** Analyze the supervision tree structure:

```elixir
defmodule MyApp.System do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      MyApp.Registry,
      MyApp.Database,
      MyApp.Cache,
      MyApp.API
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule MyApp.Database do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      {MyApp.DatabaseWorker, 1},
      {MyApp.DatabaseWorker, 2},
      {MyApp.DatabaseWorker, 3}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

**Questions:**
1. Draw the supervision tree for this system
2. What happens if DatabaseWorker 2 crashes?
3. What happens if MyApp.Database crashes?
4. What happens if MyApp.Cache crashes?
5. Why start Registry before Database?
6. What's the benefit of separate Database supervisor vs putting workers under MyApp.System?

**Analysis:**
- Errors are isolated to subtrees
- Supervisor crash affects all children
- Child crash only affects that child (with `:one_for_one`)
- Order matters: dependencies first

---

### Drill 4: Restart Strategies

**Objective:** Compare different supervisor restart strategies.

**Task:** Experiment with restart strategies:

```elixir
defmodule RestartStrategyDemo do
  use Supervisor

  def start_link(strategy) do
    Supervisor.start_link(__MODULE__, strategy, name: __MODULE__)
  end

  @impl Supervisor
  def init(strategy) do
    children = [
      worker_spec(1),
      worker_spec(2),
      worker_spec(3)
    ]

    Supervisor.init(children, strategy: strategy)
  end

  defp worker_spec(id) do
    %{
      id: id,
      start: {DemoWorker, :start_link, [id]},
      restart: :permanent
    }
  end
end

defmodule DemoWorker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: name(id))
  end

  def crash(id) do
    GenServer.call(name(id), :crash)
  end

  defp name(id), do: :"worker_#{id}"

  @impl GenServer
  def init(id) do
    IO.puts("Worker #{id} starting")
    {:ok, id}
  end

  @impl GenServer
  def handle_call(:crash, _from, state) do
    raise "Intentional crash!"
  end
end
```

**Experiments:**

**:one_for_one**
```elixir
RestartStrategyDemo.start_link(:one_for_one)
DemoWorker.crash(2)
# Observe: Only worker 2 restarts
```

**:one_for_all**
```elixir
RestartStrategyDemo.start_link(:one_for_all)
DemoWorker.crash(2)
# Observe: All workers restart
```

**:rest_for_one**
```elixir
RestartStrategyDemo.start_link(:rest_for_one)
DemoWorker.crash(1)
# Observe: Workers 1, 2, 3 restart
DemoWorker.crash(3)
# Observe: Only worker 3 restarts
```

**Questions:**
1. When would you use `:one_for_all`?
2. When would you use `:rest_for_one`?
3. What's the default/most common strategy?
4. How does child order affect `:rest_for_one`?

---

### Drill 5: Dynamic Supervision

**Objective:** Start and manage children dynamically.

**Task:** Implement an on-demand worker system:

```elixir
defmodule JobSupervisor do
  use DynamicSupervisor

  def start_link do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_job(job_id, job_data) do
    child_spec = {JobWorker, {job_id, job_data}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_job(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def count_children do
    DynamicSupervisor.count_children(__MODULE__)
  end
end

defmodule JobWorker do
  use GenServer, restart: :temporary

  def start_link({job_id, job_data}) do
    GenServer.start_link(__MODULE__, {job_id, job_data})
  end

  @impl GenServer
  def init({job_id, job_data}) do
    IO.puts("Job #{job_id} started with data: #{inspect(job_data)}")
    # Simulate work
    Process.send_after(self(), :work_done, 5000)
    {:ok, %{job_id: job_id, data: job_data}}
  end

  @impl GenServer
  def handle_info(:work_done, state) do
    IO.puts("Job #{state.job_id} completed!")
    {:stop, :normal, state}
  end
end
```

**Exercises:**
1. Start the dynamic supervisor
2. Start 5 jobs dynamically
3. Check child count
4. Manually stop one job
5. Wait for jobs to complete naturally
6. Why use `restart: :temporary` for jobs?

**Expected Output:**
```elixir
{:ok, _} = JobSupervisor.start_link()
JobSupervisor.start_job(1, %{task: "process_data"})
JobSupervisor.start_job(2, %{task: "send_email"})
JobSupervisor.count_children()
# => %{active: 2, specs: 0, supervisors: 0, workers: 2}

# After 5 seconds, jobs complete and stop
JobSupervisor.count_children()
# => %{active: 0, specs: 0, supervisors: 0, workers: 0}
```

---

### Drill 6: Restart Types

**Objective:** Understand permanent, temporary, and transient restart types.

**Task:** Compare restart behaviors:

```elixir
defmodule RestartTypeDemo do
  def demo_permanent do
    # Always restarted
    spec = %{
      id: :permanent_worker,
      start: {Worker, :start_link, [:permanent]},
      restart: :permanent
    }
  end

  def demo_temporary do
    # Never restarted
    spec = %{
      id: :temporary_worker,
      start: {Worker, :start_link, [:temporary]},
      restart: :temporary
    }
  end

  def demo_transient do
    # Restarted only if abnormal exit
    spec = %{
      id: :transient_worker,
      start: {Worker, :start_link, [:transient]},
      restart: :transient
    }
  end
end
```

**Scenarios to Test:**

| Restart Type | Normal Exit (`:normal`) | Abnormal Exit (`:error`) |
|--------------|------------------------|--------------------------|
| :permanent   | Restarted              | Restarted                |
| :temporary   | Not restarted          | Not restarted            |
| :transient   | Not restarted          | Restarted                |

**Use Cases:**
- **:permanent** - Long-lived servers (GenServer, Database pools)
- **:temporary** - One-off tasks (HTTP request handlers, short jobs)
- **:transient** - Tasks that may finish normally (startup tasks, migrations)

---

### Drill 7: "Let It Crash" Philosophy

**Objective:** Understand when to handle errors vs when to crash.

**Task:** Analyze error handling strategies:

```elixir
defmodule ErrorKernel do
  use GenServer

  # Critical process - trap exits and handle defensively
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{critical_data: load_critical_data()}}
  end

  # Defensive error handling
  def handle_call(request, _from, state) do
    try do
      result = process_request(request, state)
      {:reply, {:ok, result}, state}
    catch
      _type, _error ->
        # Don't crash - preserve state
        {:reply, {:error, :processing_failed}, state}
    end
  end
end

defmodule NormalWorker do
  use GenServer

  # Let it crash - supervisor will restart
  def handle_call({:divide, a, b}, _from, state) do
    # Will crash if b == 0 - that's OK!
    result = a / b
    {:reply, result, state}
  end

  # Handle expected errors
  def handle_call({:read_file, path}, _from, state) do
    case File.read(path) do
      {:ok, contents} ->
        {:reply, {:ok, contents}, state}
      {:error, :enoent} ->
        # Expected error - file doesn't exist
        {:reply, {:error, :not_found}, state}
      # Any other error crashes the process
    end
  end
end
```

**Analysis Questions:**
1. When should you use try/catch in a worker?
2. What's the benefit of letting processes crash?
3. What's an "error kernel" process?
4. Why handle `:enoent` but not other file errors?
5. How does immutability help with defensive try/catch?

**Principles:**
- Handle expected errors explicitly
- Let unexpected errors crash the process
- Use supervisors for recovery
- Keep error kernel processes simple
- Prefer pattern matching over defensive code

---

## Integration Exercises

### Exercise 1: Supervised Worker Pool

**Objective:** Build a supervised pool of workers with registry.

**Concepts Reinforced:**
- Supervision trees (Chapter 9)
- Registry and via tuples (Chapter 9)
- GenServer (Chapter 6)
- Process spawning (Chapter 5)

**Task:** Create a worker pool for parallel tasks:

```elixir
defmodule WorkerPool do
  use Supervisor

  @pool_size 5

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      # Start registry first
      {Registry, keys: :unique, name: WorkerPool.Registry},
      # Start pool supervisor
      PoolSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def process_task(task) do
    worker_id = choose_worker(task)
    PoolWorker.process(worker_id, task)
  end

  defp choose_worker(task) do
    # Simple round-robin based on hash
    :erlang.phash2(task, @pool_size) + 1
  end
end

defmodule PoolSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = for i <- 1..5 do
      Supervisor.child_spec(
        {PoolWorker, i},
        id: {:worker, i}
      )
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule PoolWorker do
  use GenServer

  def start_link(worker_id) do
    GenServer.start_link(
      __MODULE__,
      worker_id,
      name: via_tuple(worker_id)
    )
  end

  def process(worker_id, task) do
    GenServer.call(via_tuple(worker_id), {:process, task})
  end

  defp via_tuple(worker_id) do
    {:via, Registry, {WorkerPool.Registry, {:worker, worker_id}}}
  end

  ## Callbacks

  @impl GenServer
  def init(worker_id) do
    IO.puts("Worker #{worker_id} started")
    {:ok, %{id: worker_id, tasks_processed: 0}}
  end

  @impl GenServer
  def handle_call({:process, task}, _from, state) do
    # Simulate work
    Process.sleep(100)
    result = "Worker #{state.id} processed: #{task}"
    new_state = %{state | tasks_processed: state.tasks_processed + 1}
    {:reply, result, new_state}
  end
end
```

**Requirements:**
1. Registry for worker discovery
2. Supervisor hierarchy (System → Registry + Pool → Workers)
3. 5 worker processes
4. Round-robin task distribution
5. Track tasks completed per worker

**Test:**
```elixir
WorkerPool.start_link()

# Process tasks in parallel
tasks = for i <- 1..20 do
  Task.async(fn -> WorkerPool.process_task("task_#{i}") end)
end

results = Enum.map(tasks, &Task.await/1)
IO.inspect(results)
```

**Success Criteria:**
- All workers start successfully
- Tasks distributed across workers
- Individual worker crash doesn't affect others
- Workers restart automatically

---

### Exercise 2: Dynamic Todo List Manager

**Objective:** Extend Todo system with dynamic supervision.

**Concepts Reinforced:**
- DynamicSupervisor (Chapter 9)
- GenServer (Chapter 6)
- Registry (Chapter 9)
- TodoList abstraction (Chapter 4)

**Task:** Implement on-demand todo list servers:

```elixir
defmodule TodoSystem do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      {Registry, keys: :unique, name: TodoSystem.Registry},
      TodoCache
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TodoCache do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def server_process(list_name) do
    case start_child(list_name) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end

  defp start_child(list_name) do
    DynamicSupervisor.start_child(__MODULE__, {TodoServer, list_name})
  end
end

defmodule TodoServer do
  use GenServer, restart: :temporary

  def start_link(list_name) do
    GenServer.start_link(
      __MODULE__,
      list_name,
      name: via_tuple(list_name)
    )
  end

  def add_entry(list_name, entry) do
    GenServer.cast(via_tuple(list_name), {:add_entry, entry})
  end

  def entries(list_name, date) do
    list_name
    |> TodoCache.server_process()
    |> GenServer.call({:entries, date})
  end

  defp via_tuple(list_name) do
    {:via, Registry, {TodoSystem.Registry, {__MODULE__, list_name}}}
  end

  ## Callbacks

  @impl GenServer
  def init(list_name) do
    IO.puts("Starting TodoServer for #{list_name}")
    {:ok, {list_name, TodoList.new()}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {list_name, todo_list}) do
    new_list = TodoList.add_entry(todo_list, entry)
    {:noreply, {list_name, new_list}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {list_name, todo_list}) do
    entries = TodoList.entries(todo_list, date)
    {:reply, entries, {list_name, todo_list}}
  end
end
```

**Requirements:**
1. Start todo servers on demand
2. Multiple users can have separate lists
3. Lists are temporary (don't restart on crash)
4. Registry-based discovery
5. Concurrent access works correctly

**Test Scenario:**
```elixir
TodoSystem.start_link()

# Create entries for Bob
bob_pid = TodoCache.server_process("Bob's list")
TodoServer.add_entry("Bob's list", %{date: ~D[2026-01-22], title: "Dentist"})

# Create entries for Alice
alice_pid = TodoCache.server_process("Alice's list")
TodoServer.add_entry("Alice's list", %{date: ~D[2026-01-22], title: "Meeting"})

# They're different processes
bob_pid != alice_pid  # => true

# Both work independently
TodoServer.entries("Bob's list", ~D[2026-01-22])
TodoServer.entries("Alice's list", ~D[2026-01-22])

# Crash Bob's server
Process.exit(bob_pid, :kill)

# Alice unaffected
TodoServer.entries("Alice's list", ~D[2026-01-22])

# Bob's recreated on next access
new_bob_pid = TodoCache.server_process("Bob's list")
new_bob_pid != bob_pid  # => true (different PID)
```

---

### Exercise 3: Fault-Tolerant Database Pool

**Objective:** Build a database connection pool with isolation.

**Concepts Reinforced:**
- Supervision trees (Chapter 9)
- Restart strategies (Chapter 9)
- GenServer (Chapter 6)
- Process pools (Chapter 5)

**Task:**

```elixir
defmodule DatabaseSystem do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      {Registry, keys: :unique, name: DB.Registry},
      DatabasePool
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule DatabasePool do
  use Supervisor

  @pool_size 3

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = for i <- 1..@pool_size do
      Supervisor.child_spec(
        {DatabaseWorker, i},
        id: {:db_worker, i},
        restart: :permanent
      )
    end

    Supervisor.init(children, strategy: :one_for_one)
  end

  def query(sql) do
    worker_id = choose_worker(sql)
    DatabaseWorker.query(worker_id, sql)
  end

  defp choose_worker(sql) do
    :erlang.phash2(sql, @pool_size) + 1
  end
end

defmodule DatabaseWorker do
  use GenServer

  def start_link(worker_id) do
    GenServer.start_link(
      __MODULE__,
      worker_id,
      name: via_tuple(worker_id)
    )
  end

  def query(worker_id, sql) do
    GenServer.call(via_tuple(worker_id), {:query, sql})
  end

  defp via_tuple(worker_id) do
    {:via, Registry, {DB.Registry, {:db_worker, worker_id}}}
  end

  ## Callbacks

  @impl GenServer
  def init(worker_id) do
    # Simulate connection
    conn = connect_to_database(worker_id)
    {:ok, %{id: worker_id, conn: conn, query_count: 0}}
  end

  @impl GenServer
  def handle_call({:query, sql}, _from, state) do
    # Simulate query execution
    result = execute_query(state.conn, sql)
    new_state = %{state | query_count: state.query_count + 1}
    {:reply, result, new_state}
  rescue
    e ->
      # Log error but let process crash
      IO.puts("Query failed: #{inspect(e)}")
      reraise e, __STACKTRACE__
  end

  defp connect_to_database(worker_id) do
    IO.puts("DB Worker #{worker_id} connecting...")
    {:connection, worker_id}
  end

  defp execute_query(conn, sql) do
    # Simulate query
    Process.sleep(50)
    {:ok, "Result for: #{sql}"}
  end
end
```

**Requirements:**
1. Pool of 3 database workers
2. Each worker manages its own connection
3. Worker crash doesn't affect others
4. Failed queries crash the worker (let it crash)
5. Supervisor restarts crashed workers with fresh connections

**Test Fault Tolerance:**
```elixir
DatabaseSystem.start_link()

# Normal queries work
DatabasePool.query("SELECT * FROM users")
# => {:ok, "Result for: SELECT * FROM users"}

# Kill a worker
[{pid, _}] = Registry.lookup(DB.Registry, {:db_worker, 2})
Process.exit(pid, :kill)

# Worker automatically restarted
# Queries continue to work
DatabasePool.query("SELECT * FROM posts")
# => {:ok, "Result for: SELECT * FROM posts"}
```

---

### Exercise 4: Supervised Pipeline

**Objective:** Create a multi-stage processing pipeline with isolation.

**Concepts Reinforced:**
- Supervision trees (Chapter 9)
- `:rest_for_one` strategy (Chapter 9)
- GenServer (Chapter 6)
- Message passing (Chapter 5)

**Task:** Build a data processing pipeline where stages depend on upstream stages:

```elixir
defmodule Pipeline do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      {Stage, {:input, nil}},
      {Stage, {:process, :input}},
      {Stage, {:output, :process}}
    ]

    # If upstream crashes, downstream should restart
    Supervisor.init(children, strategy: :rest_for_one)
  end

  def submit(data) do
    Stage.submit(:input, data)
  end
end

defmodule Stage do
  use GenServer

  def start_link({name, upstream}) do
    GenServer.start_link(__MODULE__, {name, upstream}, name: name)
  end

  def submit(stage, data) do
    GenServer.cast(stage, {:data, data})
  end

  ## Callbacks

  @impl GenServer
  def init({name, upstream}) do
    IO.puts("Stage #{name} started (upstream: #{inspect(upstream)})")
    {:ok, %{name: name, upstream: upstream, processed: 0}}
  end

  @impl GenServer
  def handle_cast({:data, data}, state) do
    IO.puts("#{state.name} processing: #{inspect(data)}")

    # Process data
    processed = transform(state.name, data)
    new_state = %{state | processed: state.processed + 1}

    # Pass to next stage
    if downstream = next_stage(state.name) do
      Stage.submit(downstream, processed)
    end

    {:noreply, new_state}
  end

  defp transform(:input, data), do: {:validated, data}
  defp transform(:process, {:validated, data}), do: {:processed, data * 2}
  defp transform(:output, {:processed, data}), do: IO.puts("Output: #{data}")

  defp next_stage(:input), do: :process
  defp next_stage(:process), do: :output
  defp next_stage(:output), do: nil
end
```

**Requirements:**
1. Three stages: input → process → output
2. Use `:rest_for_one` strategy
3. Crash in input stage restarts all stages
4. Crash in output stage only restarts output

**Test:**
```elixir
Pipeline.start_link()

Pipeline.submit(5)
# => Input processing: 5
# => Process processing: {:validated, 5}
# => Output processing: {:processed, 10}
# => Output: 10

# Kill process stage
Process.exit(Process.whereis(:process), :kill)
# Observe: process and output restart, input stays running
```

**Analysis:**
- Why use `:rest_for_one` for a pipeline?
- What happens if `:input` crashes vs `:output` crashes?
- When would you use `:one_for_all` instead?

---

## Capstone Project: Resilient Task Queue System

### Project Description

Build a production-ready distributed task queue with fine-grained supervision, dynamic workers, priority queues, and comprehensive fault tolerance. The system should isolate failures, recover automatically, and maintain high availability even when individual components fail.

### Architecture Overview

```
TaskQueue.System (Supervisor)
├── Registry (Process discovery)
├── QueueManager (Supervisor)
│   ├── PriorityQueue (GenServer)
│   ├── ScheduledQueue (GenServer)
│   └── DeadLetterQueue (GenServer)
├── WorkerPool (DynamicSupervisor)
│   ├── Worker 1 (temporary)
│   ├── Worker 2 (temporary)
│   └── Worker N (temporary)
└── TaskStore (Supervisor)
    ├── StoreWorker 1 (permanent)
    ├── StoreWorker 2 (permanent)
    └── StoreWorker 3 (permanent)
```

### Requirements

#### 1. Core Queue Manager

```elixir
defmodule TaskQueue.Manager do
  use GenServer

  defstruct [
    :high_priority,
    :normal_priority,
    :low_priority,
    :scheduled,
    :processing,
    :stats
  ]

  ## API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def enqueue(task, priority \\ :normal) do
    GenServer.call(__MODULE__, {:enqueue, task, priority})
  end

  def schedule(task, run_at) do
    GenServer.call(__MODULE__, {:schedule, task, run_at})
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  ## Callbacks

  @impl GenServer
  def init(_) do
    Process.send_after(self(), :check_scheduled, 1000)

    state = %__MODULE__{
      high_priority: :queue.new(),
      normal_priority: :queue.new(),
      low_priority: :queue.new(),
      scheduled: [],
      processing: %{},
      stats: %{enqueued: 0, completed: 0, failed: 0}
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:enqueue, task, priority}, _from, state) do
    task_id = generate_id()
    task_with_id = %{id: task_id, task: task, enqueued_at: System.system_time()}

    new_state = add_to_queue(state, task_with_id, priority)
    new_state = update_stats(new_state, :enqueued)

    # Notify workers
    notify_workers()

    {:reply, {:ok, task_id}, new_state}
  end

  def handle_call({:schedule, task, run_at}, _from, state) do
    task_id = generate_id()
    scheduled_task = %{id: task_id, task: task, run_at: run_at}
    new_scheduled = [scheduled_task | state.scheduled]

    {:reply, {:ok, task_id}, %{state | scheduled: new_scheduled}}
  end

  def handle_call(:dequeue, _from, state) do
    case get_next_task(state) do
      {task, new_state} ->
        # Mark as processing
        new_processing = Map.put(new_state.processing, task.id, task)
        final_state = %{new_state | processing: new_processing}
        {:reply, {:ok, task}, final_state}

      nil ->
        {:reply, :empty, state}
    end
  end

  def handle_call(:stats, _from, state) do
    stats = %{
      queued: queue_sizes(state),
      scheduled: length(state.scheduled),
      processing: map_size(state.processing),
      stats: state.stats
    }
    {:reply, stats, state}
  end

  @impl GenServer
  def handle_info(:check_scheduled, state) do
    now = System.system_time()
    {ready, still_scheduled} = Enum.split_with(state.scheduled, fn task ->
      task.run_at <= now
    end)

    # Move ready tasks to normal queue
    new_state = Enum.reduce(ready, state, fn task, acc ->
      add_to_queue(acc, task, :normal)
    end)

    new_state = %{new_state | scheduled: still_scheduled}

    if ready != [] do
      notify_workers()
    end

    Process.send_after(self(), :check_scheduled, 1000)
    {:noreply, new_state}
  end

  def handle_info({:task_completed, task_id}, state) do
    new_processing = Map.delete(state.processing, task_id)
    new_state = %{state | processing: new_processing}
    new_state = update_stats(new_state, :completed)
    {:noreply, new_state}
  end

  def handle_info({:task_failed, task_id, reason}, state) do
    # Move to dead letter queue or retry
    new_processing = Map.delete(state.processing, task_id)
    new_state = %{state | processing: new_processing}
    new_state = update_stats(new_state, :failed)

    TaskQueue.DeadLetterQueue.add(task_id, reason)

    {:noreply, new_state}
  end

  ## Private

  defp add_to_queue(state, task, :high) do
    %{state | high_priority: :queue.in(task, state.high_priority)}
  end
  defp add_to_queue(state, task, :normal) do
    %{state | normal_priority: :queue.in(task, state.normal_priority)}
  end
  defp add_to_queue(state, task, :low) do
    %{state | low_priority: :queue.in(task, state.low_priority)}
  end

  defp get_next_task(state) do
    cond do
      !:queue.is_empty(state.high_priority) ->
        {{:value, task}, new_queue} = :queue.out(state.high_priority)
        {task, %{state | high_priority: new_queue}}

      !:queue.is_empty(state.normal_priority) ->
        {{:value, task}, new_queue} = :queue.out(state.normal_priority)
        {task, %{state | normal_priority: new_queue}}

      !:queue.is_empty(state.low_priority) ->
        {{:value, task}, new_queue} = :queue.out(state.low_priority)
        {task, %{state | low_priority: new_queue}}

      true ->
        nil
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end

  defp queue_sizes(state) do
    %{
      high: :queue.len(state.high_priority),
      normal: :queue.len(state.normal_priority),
      low: :queue.len(state.low_priority)
    }
  end

  defp update_stats(state, metric) do
    new_stats = Map.update!(state.stats, metric, &(&1 + 1))
    %{state | stats: new_stats}
  end

  defp notify_workers do
    Registry.dispatch(TaskQueue.Registry, :workers, fn entries ->
      for {pid, _} <- entries, do: send(pid, :work_available)
    end)
  end
end
```

#### 2. Dynamic Worker Pool

```elixir
defmodule TaskQueue.WorkerPool do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 100)
  end

  def start_worker do
    DynamicSupervisor.start_child(__MODULE__, TaskQueue.Worker)
  end

  def worker_count do
    DynamicSupervisor.count_children(__MODULE__)
  end
end

defmodule TaskQueue.Worker do
  use GenServer, restart: :temporary

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl GenServer
  def init(_) do
    # Subscribe to work notifications
    Registry.register(TaskQueue.Registry, :workers, nil)

    # Start working
    send(self(), :fetch_work)

    {:ok, %{tasks_completed: 0}}
  end

  @impl GenServer
  def handle_info(:fetch_work, state) do
    case TaskQueue.Manager.dequeue() do
      {:ok, task} ->
        process_task(task)
        new_state = %{state | tasks_completed: state.tasks_completed + 1}
        send(self(), :fetch_work)
        {:noreply, new_state}

      :empty ->
        # Wait for notification
        {:noreply, state}
    end
  end

  def handle_info(:work_available, state) do
    send(self(), :fetch_work)
    {:noreply, state}
  end

  defp process_task(task) do
    try do
      # Execute the task
      result = execute_task(task.task)

      # Notify manager
      send(TaskQueue.Manager, {:task_completed, task.id})

      result
    rescue
      e ->
        # Notify manager of failure
        send(TaskQueue.Manager, {:task_failed, task.id, Exception.message(e)})

        # Don't crash - just continue to next task
        :error
    end
  end

  defp execute_task(%{type: :compute, data: data}) do
    # Simulate work
    Process.sleep(100)
    {:ok, data * 2}
  end

  defp execute_task(%{type: :io, path: path}) do
    # Simulate IO
    Process.sleep(200)
    {:ok, "processed #{path}"}
  end

  defp execute_task(%{type: :network, url: url}) do
    # Simulate network call
    Process.sleep(300)
    {:ok, "fetched #{url}"}
  end
end
```

#### 3. Persistent Task Store

```elixir
defmodule TaskQueue.Store do
  use Supervisor

  @pool_size 3

  def start_link(_) do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = for i <- 1..@pool_size do
      Supervisor.child_spec(
        {TaskQueue.StoreWorker, i},
        id: {:store_worker, i}
      )
    end

    Supervisor.init(children, strategy: :one_for_one)
  end

  def save(task_id, task_data) do
    worker_id = :erlang.phash2(task_id, @pool_size) + 1
    TaskQueue.StoreWorker.save(worker_id, task_id, task_data)
  end

  def load(task_id) do
    worker_id = :erlang.phash2(task_id, @pool_size) + 1
    TaskQueue.StoreWorker.load(worker_id, task_id)
  end
end

defmodule TaskQueue.StoreWorker do
  use GenServer

  def start_link(worker_id) do
    GenServer.start_link(
      __MODULE__,
      worker_id,
      name: via_tuple(worker_id)
    )
  end

  def save(worker_id, task_id, task_data) do
    GenServer.cast(via_tuple(worker_id), {:save, task_id, task_data})
  end

  def load(worker_id, task_id) do
    GenServer.call(via_tuple(worker_id), {:load, task_id})
  end

  defp via_tuple(worker_id) do
    {:via, Registry, {TaskQueue.Registry, {:store_worker, worker_id}}}
  end

  @impl GenServer
  def init(worker_id) do
    db_path = "priv/tasks_#{worker_id}.db"
    File.mkdir_p!("priv")
    {:ok, %{worker_id: worker_id, db_path: db_path}}
  end

  @impl GenServer
  def handle_cast({:save, task_id, task_data}, state) do
    data = :erlang.term_to_binary({task_id, task_data})
    file_path = Path.join(state.db_path, task_id)
    File.write!(file_path, data)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:load, task_id}, _from, state) do
    file_path = Path.join(state.db_path, task_id)
    result = case File.read(file_path) do
      {:ok, binary} ->
        {_task_id, task_data} = :erlang.binary_to_term(binary)
        {:ok, task_data}
      {:error, :enoent} ->
        {:error, :not_found}
    end
    {:reply, result, state}
  end
end
```

#### 4. System Supervisor

```elixir
defmodule TaskQueue.System do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_) do
    children = [
      # Start registry first
      {Registry, keys: :duplicate, name: TaskQueue.Registry},

      # Start storage layer
      TaskQueue.Store,

      # Start queue manager
      TaskQueue.Manager,

      # Start dead letter queue
      TaskQueue.DeadLetterQueue,

      # Start worker pool
      TaskQueue.WorkerPool
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### Additional Features to Implement

#### 1. Dead Letter Queue
```elixir
defmodule TaskQueue.DeadLetterQueue do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def add(task_id, reason) do
    GenServer.cast(__MODULE__, {:add, task_id, reason, System.system_time()})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def retry(task_id) do
    GenServer.call(__MODULE__, {:retry, task_id})
  end
end
```

#### 2. Auto-scaling Workers
```elixir
defmodule TaskQueue.Autoscaler do
  use GenServer

  # Monitor queue depth and spawn/stop workers
  def init(_) do
    schedule_check()
    {:ok, %{min_workers: 2, max_workers: 10}}
  end

  def handle_info(:check_scaling, state) do
    stats = TaskQueue.Manager.stats()
    total_queued = stats.queued.high + stats.queued.normal + stats.queued.low

    cond do
      total_queued > 50 -> scale_up()
      total_queued < 10 -> scale_down()
      true -> :ok
    end

    schedule_check()
    {:noreply, state}
  end
end
```

#### 3. Task Retry Logic
```elixir
defmodule TaskQueue.RetryPolicy do
  def should_retry?(%{attempts: attempts}), do: attempts < 3

  def backoff_delay(attempt) do
    # Exponential backoff: 1s, 2s, 4s
    :math.pow(2, attempt - 1) * 1000 |> round()
  end
end
```

### Bonus Challenges

1. **Task Dependencies**
   - Support tasks that depend on other tasks completing first
   - Build a DAG (directed acyclic graph) of task dependencies

2. **Rate Limiting**
   - Limit task execution rate (e.g., max 10 per second)
   - Per-task-type rate limits

3. **Observability**
   - Export metrics (queue depth, processing time, failure rate)
   - Task execution tracing

4. **Persistence**
   - Survive system restarts
   - Reload pending tasks from disk

5. **Distributed Queue**
   - Run on multiple nodes
   - Distribute work across cluster

6. **Priority Inheritance**
   - Boost priority of blocking tasks
   - Prevent priority inversion

### Evaluation Criteria

**Supervision Tree Design (25 points)**
- Proper hierarchy (5 pts)
- Appropriate restart strategies (5 pts)
- Error isolation (5 pts)
- Registry integration (5 pts)
- Child specifications (5 pts)

**Fault Tolerance (25 points)**
- Worker crash handling (10 pts)
- Queue manager resilience (5 pts)
- Store worker recovery (5 pts)
- No data loss (5 pts)

**Dynamic Supervision (20 points)**
- DynamicSupervisor usage (10 pts)
- Worker lifecycle management (5 pts)
- Temporary worker strategy (5 pts)

**Features (20 points)**
- Priority queues (5 pts)
- Scheduled tasks (5 pts)
- Dead letter queue (5 pts)
- Statistics tracking (5 pts)

**Code Quality (10 points)**
- Clean architecture (5 pts)
- Error handling (3 pts)
- Documentation (2 pts)

### Testing Scenarios

```elixir
# 1. Basic functionality
TaskQueue.System.start_link()
TaskQueue.Manager.enqueue(%{type: :compute, data: 10}, :high)
TaskQueue.Manager.enqueue(%{type: :io, path: "/tmp/file"}, :normal)

# 2. Scheduled tasks
future = System.system_time() + 5_000_000_000
TaskQueue.Manager.schedule(%{type: :network, url: "http://api.com"}, future)

# 3. Worker management
TaskQueue.WorkerPool.start_worker()
TaskQueue.WorkerPool.start_worker()
TaskQueue.WorkerPool.worker_count()

# 4. Fault tolerance
stats = TaskQueue.Manager.stats()
# Kill a worker
[{pid, _}] = Registry.lookup(TaskQueue.Registry, :workers)
Process.exit(pid, :kill)
# Verify system continues working

# 5. Load test
for i <- 1..1000 do
  priority = Enum.random([:high, :normal, :low])
  TaskQueue.Manager.enqueue(%{type: :compute, data: i}, priority)
end

# Monitor stats
Stream.interval(1000)
|> Stream.take(10)
|> Enum.each(fn _ ->
  IO.inspect(TaskQueue.Manager.stats())
end)
```

---

## Success Checklist

Before moving to Chapter 10, ensure you can:

- [ ] Understand supervision tree organization
- [ ] Use Registry for process discovery
- [ ] Create via tuples for OTP process registration
- [ ] Implement different restart strategies (`:one_for_one`, `:one_for_all`, `:rest_for_one`)
- [ ] Choose appropriate restart types (`:permanent`, `:temporary`, `:transient`)
- [ ] Use DynamicSupervisor for on-demand process creation
- [ ] Design hierarchical supervision trees
- [ ] Isolate error effects to subtrees
- [ ] Apply "let it crash" philosophy correctly
- [ ] Know when to handle errors explicitly vs letting processes crash
- [ ] Understand error kernel concept
- [ ] Implement child specifications correctly
- [ ] Use `Supervisor.child_spec/2` to customize specs
- [ ] Handle process restarts gracefully
- [ ] Understand process lifecycle in supervision trees

---

## Looking Ahead

Chapter 10 introduces higher-level OTP abstractions beyond GenServer:
- **Task** - For one-off computations and async/await patterns
- **Agent** - For simple state management
- **ETS** - For in-memory table storage with concurrent access
- **Periodic** jobs and schedulers

These tools complement supervisors and GenServers, providing specialized solutions for common patterns!
