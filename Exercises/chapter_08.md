# Chapter 8: Fault Tolerance Basics - Learning Exercises

## Chapter Summary

Chapter 8 establishes fault tolerance as a core BEAM capability, built on the principle that errors will inevitably occur and systems must recover automatically through isolation and supervision rather than error prevention. Process isolation ensures crashes remain localized, while links and monitors provide mechanisms to detect terminations and propagate errors bidirectionally or unidirectionally. Supervisors leverage these primitives to automatically restart crashed processes according to configured strategies, creating self-healing systems where failures in individual components don't compromise overall system availability, embodying the "let it crash" philosophy central to Erlang/Elixir fault tolerance.

---

## Concept Drills

### Drill 1: Error Types (Error, Exit, Throw)

**Objective:** Understand the three types of runtime errors in BEAM.

**Task:** Experiment with each error type:

```elixir
# 1. Errors - Programming mistakes
defmodule ErrorExamples do
  def arithmetic_error do
    1 / 0
  end

  def pattern_match_error do
    {:ok, value} = {:error, "failed"}
  end

  def function_clause_error do
    func = fn
      :ok -> "success"
    end
    func.(:error)  # No matching clause
  end

  def custom_error do
    raise "Something went wrong"
  end

  def custom_error_with_type do
    raise ArgumentError, message: "Invalid argument"
  end
end

# 2. Exits - Deliberate process termination
defmodule ExitExamples do
  def normal_exit do
    exit(:normal)  # Normal termination
  end

  def abnormal_exit do
    exit(:shutdown)  # Abnormal but intentional
  end

  def exit_with_reason do
    exit({:error, :database_unreachable})
  end
end

# 3. Throws - Non-local returns (rare, avoid if possible)
defmodule ThrowExamples do
  def early_return do
    throw({:result, 42})
  end

  def nested_throw do
    Enum.find(1..1000, fn x ->
      if x > 500, do: throw(:too_high)
      rem(x, 13) == 0 and rem(x, 7) == 0
    end)
  end
end
```

**Test Each Type:**
```elixir
# Errors
try do
  ErrorExamples.arithmetic_error()
catch
  :error, %ArithmeticError{} -> IO.puts("Caught arithmetic error")
end

# Exits
try do
  ExitExamples.abnormal_exit()
catch
  :exit, :shutdown -> IO.puts("Caught exit signal")
end

# Throws
try do
  ThrowExamples.early_return()
catch
  :throw, {:result, value} -> IO.puts("Caught throw: #{value}")
end
```

---

### Drill 2: Try/Catch/Rescue

**Objective:** Master error handling with try expressions.

**Task:** Build a robust error handler:

```elixir
defmodule SafeOperations do
  # Basic try/catch
  def safe_divide(a, b) do
    try do
      result = a / b
      {:ok, result}
    catch
      :error, %ArithmeticError{} -> {:error, :division_by_zero}
    end
  end

  # Multiple catch clauses
  def parse_and_process(input) do
    try do
      value = String.to_integer(input)
      process(value)
    catch
      :error, %ArgumentError{} ->
        {:error, :invalid_format}

      :exit, reason ->
        {:error, {:process_exited, reason}}

      :throw, value ->
        {:error, {:thrown, value}}
    end
  end

  # After clause for cleanup
  def read_file_safe(path) do
    file = File.open!(path)

    try do
      content = IO.read(file, :all)
      {:ok, content}
    catch
      error, reason ->
        {:error, {error, reason}}
    after
      File.close(file)
      IO.puts("File closed")
    end
  end

  # Rescue for specific exceptions (Elixir-specific)
  def rescue_example do
    try do
      raise ArgumentError, "Invalid input"
    rescue
      ArgumentError -> {:error, :bad_argument}
      RuntimeError -> {:error, :runtime_error}
    end
  end

  defp process(value) when value > 100, do: throw(:too_large)
  defp process(value) when value < 0, do: exit(:negative_value)
  defp process(value), do: value * 2
end
```

**Questions:**
1. What's the difference between `catch` and `rescue`?
2. When does the `after` block execute?
3. What does `try` return if no error occurs?
4. Can you have both `rescue` and `catch`?

---

### Drill 3: Process Links

**Objective:** Understand bidirectional error propagation through links.

**Task:** Experiment with process linking:

```elixir
defmodule LinkExamples do
  # Basic linking - both processes die
  def linked_crash do
    parent = self()

    spawn_link(fn ->
      IO.puts("Child: Started (#{inspect(self())})")
      Process.sleep(1000)
      raise "Child crashed!"
    end)

    Process.sleep(2000)
    IO.puts("Parent: Still alive")  # Won't print if child crashes
  end

  # Trapping exits - survive the crash
  def trap_exit_example do
    Process.flag(:trap_exit, true)

    child = spawn_link(fn ->
      Process.sleep(1000)
      raise "Child crashed!"
    end)

    receive do
      {:EXIT, ^child, reason} ->
        IO.puts("Child #{inspect(child)} exited: #{inspect(reason)}")
        :child_died
    after
      3000 ->
        :timeout
    end
  end

  # Multiple linked processes
  def chain_reaction do
    Process.flag(:trap_exit, true)

    # Create a chain of linked processes
    pids = Enum.map(1..3, fn i ->
      spawn_link(fn ->
        IO.puts("Process #{i} started")
        Process.sleep(:infinity)
      end)
    end)

    # Kill one - what happens to others?
    [first | _rest] = pids
    Process.sleep(100)
    Process.exit(first, :kill)

    # Check which ones died
    Process.sleep(100)

    Enum.each(pids, fn pid ->
      alive = Process.alive?(pid)
      IO.puts("#{inspect(pid)}: #{if alive, do: "alive", else: "dead"}")
    end)
  end

  # Normal exits don't propagate
  def normal_exit_link do
    Process.flag(:trap_exit, true)

    child = spawn_link(fn ->
      Process.sleep(500)
      IO.puts("Child finishing normally")
      # Function returns normally - exit(:normal)
    end)

    receive do
      {:EXIT, ^child, :normal} ->
        IO.puts("Child exited normally - received :normal")
    after
      2000 -> :timeout
    end
  end
end
```

**Test:**
```elixir
# Without trap - both die
spawn(fn ->
  LinkExamples.linked_crash()
end)

# With trap - parent survives
LinkExamples.trap_exit_example()

# Chain reaction
LinkExamples.chain_reaction()

# Normal exit
LinkExamples.normal_exit_link()
```

**Key Insights:**
- Links are bidirectional
- By default, abnormal exit propagates
- Trapping exits converts signals to messages
- Normal exit (:normal) doesn't kill linked processes

---

### Drill 4: Process Monitors

**Objective:** Understand unidirectional process watching.

**Task:** Compare monitors with links:

```elixir
defmodule MonitorExamples do
  # Basic monitoring - unidirectional
  def basic_monitor do
    target = spawn(fn ->
      Process.sleep(1000)
      exit(:some_reason)
    end)

    ref = Process.monitor(target)
    IO.puts("Monitoring #{inspect(target)} with ref #{inspect(ref)}")

    receive do
      {:DOWN, ^ref, :process, ^target, reason} ->
        IO.puts("Target died: #{inspect(reason)}")
    end
  end

  # Monitor vs Link comparison
  def compare_monitor_and_link do
    IO.puts("\n=== Monitor (unidirectional) ===")

    target1 = spawn(fn ->
      Process.sleep(500)
      exit(:crash)
    end)

    Process.monitor(target1)

    receive do
      {:DOWN, _ref, :process, _pid, reason} ->
        IO.puts("Got :DOWN message: #{inspect(reason)}")
        IO.puts("Observer still alive!")
    end

    IO.puts("\n=== Link (bidirectional) ===")
    Process.flag(:trap_exit, true)

    target2 = spawn_link(fn ->
      Process.sleep(500)
      exit(:crash)
    end)

    receive do
      {:EXIT, _pid, reason} ->
        IO.puts("Got :EXIT message: #{inspect(reason)}")
        IO.puts("Observer still alive (because trapping)!")
    end
  end

  # Multiple monitors
  def monitor_multiple do
    targets = for i <- 1..3 do
      spawn(fn ->
        Process.sleep(i * 500)
        exit({:finished, i})
      end)
    end

    refs = Enum.map(targets, &Process.monitor/1)

    # Wait for all to finish
    Enum.each(refs, fn _ref ->
      receive do
        {:DOWN, _ref, :process, pid, reason} ->
          IO.puts("Process #{inspect(pid)} down: #{inspect(reason)}")
      end
    end)
  end

  # Demonitor
  def demonitor_example do
    target = spawn(fn -> Process.sleep(:infinity) end)

    ref = Process.monitor(target)
    IO.puts("Monitoring...")

    Process.sleep(500)
    Process.demonitor(ref)
    IO.puts("Stopped monitoring")

    Process.exit(target, :kill)
    IO.puts("Killed target")

    receive do
      {:DOWN, _, _, _, _} -> IO.puts("Got DOWN message")
    after
      1000 -> IO.puts("No DOWN message received")
    end
  end
end
```

**Monitor vs Link Decision Guide:**

Use **Links** when:
- Both processes depend on each other
- Want automatic crash propagation
- Building supervision hierarchies

Use **Monitors** when:
- Only one process needs to know about termination
- Don't want crashes to propagate
- Monitoring multiple processes
- Need monitoring information (ref, reason)

---

### Drill 5: Basic Supervisor

**Objective:** Create and understand simple supervisors.

**Task:** Build a supervisor from scratch:

```elixir
defmodule MyWorker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def crash(id) do
    GenServer.cast(via_tuple(id), :crash)
  end

  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  @impl GenServer
  def init(id) do
    IO.puts("Worker #{id} starting with PID #{inspect(self())}")
    {:ok, %{id: id, started_at: DateTime.utc_now()}}
  end

  @impl GenServer
  def handle_cast(:crash, state) do
    raise "Worker #{state.id} crashing!"
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  defp via_tuple(id), do: {:via, Registry, {MyRegistry, id}}
end

# Start registry
{:ok, _} = Registry.start_link(keys: :unique, name: MyRegistry)

# Simple supervisor
{:ok, sup} = Supervisor.start_link(
  [
    {MyWorker, 1},
    {MyWorker, 2},
    {MyWorker, 3}
  ],
  strategy: :one_for_one
)

# Test restart
IO.inspect(MyWorker.get_state(1))
MyWorker.crash(1)
Process.sleep(100)
IO.inspect(MyWorker.get_state(1))  # New PID, fresh state
```

---

### Drill 6: Child Specifications

**Objective:** Understand how supervisors start children.

**Task:** Explore child specification formats:

```elixir
defmodule Worker do
  use GenServer

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    IO.puts("Starting with opts: #{inspect(opts)}")
    {:ok, opts}
  end

  # Custom child_spec
  def child_spec(opts) do
    id = Keyword.get(opts, :id, __MODULE__)
    restart = Keyword.get(opts, :restart, :permanent)

    %{
      id: id,
      start: {__MODULE__, :start_link, [opts]},
      restart: restart,
      type: :worker
    }
  end
end

# Different ways to specify children:

# 1. Just module (uses default child_spec)
Supervisor.start_link([Worker], strategy: :one_for_one)

# 2. {module, arg} tuple
Supervisor.start_link(
  [{Worker, [name: :my_worker, value: 42]}],
  strategy: :one_for_one
)

# 3. Full child specification map
Supervisor.start_link(
  [
    %{
      id: :custom_worker,
      start: {Worker, :start_link, [[name: :custom, value: 99]]},
      restart: :transient,
      shutdown: 5000
    }
  ],
  strategy: :one_for_one
)

# 4. Child spec with custom options
Supervisor.start_link(
  [{Worker, [id: :worker1, name: :w1, restart: :temporary]}],
  strategy: :one_for_one
)
```

**Child Spec Fields:**
- `:id` - Unique identifier (required)
- `:start` - `{module, function, args}` tuple (required)
- `:restart` - `:permanent`, `:temporary`, `:transient` (default: `:permanent`)
- `:shutdown` - Time in ms or `:brutal_kill` (default: `5000`)
- `:type` - `:worker` or `:supervisor` (default: `:worker`)

---

## Integration Exercises

### Exercise 1: Fault-Tolerant TodoServer

**Objective:** Add supervision to TodoServer from previous chapters.

**Concepts Reinforced:**
- GenServer (Chapter 6)
- TodoList (Chapter 4)
- Supervisors (Chapter 8)
- Process links (Chapter 8)

**Task:** Create supervised todo system:

```elixir
defmodule TodoServer do
  use GenServer

  # Must use start_link for supervision
  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def add_entry(name, entry) do
    GenServer.cast(via_tuple(name), {:add_entry, entry})
  end

  def entries(name, date) do
    GenServer.call(via_tuple(name), {:entries, date})
  end

  @impl GenServer
  def init(name) do
    IO.puts("Starting TodoServer for: #{name}")
    {:ok, {name, TodoList.new()}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, list}) do
    {:noreply, {name, TodoList.add_entry(list, entry)}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, TodoList.entries(list, date), {name, list}}
  end

  defp via_tuple(name), do: {:via, Registry, {TodoRegistry, name}}
end

defmodule TodoSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_child(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  @impl Supervisor
  def init(_) do
    children = [
      {Registry, keys: :unique, name: TodoRegistry},
      {DynamicSupervisor, name: TodoDynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule TodoSystem do
  def start do
    {:ok, _} = TodoSupervisor.start_link()
  end

  def new_list(name) do
    DynamicSupervisor.start_child(
      TodoDynamicSupervisor,
      {TodoServer, name}
    )
  end
end
```

**Test Fault Tolerance:**
```elixir
TodoSystem.start()
TodoSystem.new_list("shopping")

TodoServer.add_entry("shopping", %{date: ~D[2024-01-22], title: "Milk"})

# Crash the server
pid = GenServer.whereis({:via, Registry, {TodoRegistry, "shopping"}})
Process.exit(pid, :kill)

# It restarts!
Process.sleep(100)
TodoServer.add_entry("shopping", %{date: ~D[2024-01-22], title: "Bread"})
```

---

### Exercise 2: Worker Pool with Supervision

**Objective:** Build supervised worker pool.

**Concepts Reinforced:**
- Process pools (Chapter 5)
- Supervisors (Chapter 8)
- Dynamic children (Chapter 8)

**Task:**

```elixir
defmodule PoolWorker do
  use GenServer

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def work(pid, task) do
    GenServer.call(pid, {:work, task})
  end

  @impl GenServer
  def init(id) do
    IO.puts("Worker #{id} started")
    {:ok, %{id: id, tasks_completed: 0}}
  end

  @impl GenServer
  def handle_call({:work, task}, _from, state) do
    # Simulate work
    result = task.()
    new_state = %{state | tasks_completed: state.tasks_completed + 1}
    {:reply, result, new_state}
  end
end

defmodule WorkerPoolSupervisor do
  use Supervisor

  def start_link(pool_size) do
    Supervisor.start_link(__MODULE__, pool_size, name: __MODULE__)
  end

  def get_worker(n) do
    children = Supervisor.which_children(__MODULE__)
    {_, pid, _, _} = Enum.at(children, rem(n, length(children)))
    pid
  end

  @impl Supervisor
  def init(pool_size) do
    children = for i <- 1..pool_size do
      Supervisor.child_spec({PoolWorker, i}, id: {:worker, i})
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

**Usage:**
```elixir
{:ok, _} = WorkerPoolSupervisor.start_link(5)

# Use workers
worker = WorkerPoolSupervisor.get_worker(0)
PoolWorker.work(worker, fn -> 1 + 1 end)

# If one crashes, it restarts
Process.exit(worker, :kill)
Process.sleep(100)

# Pool still works
new_worker = WorkerPoolSupervisor.get_worker(0)
PoolWorker.work(new_worker, fn -> 2 + 2 end)
```

---

## Capstone Project: Fault-Tolerant HTTP Client Pool

### Project Description

Build a production-ready supervised HTTP client pool with automatic retries, circuit breakers, and failure isolation.

### Requirements

#### 1. HTTP Worker

```elixir
defmodule HttpWorker do
  use GenServer

  defstruct [:id, :status, requests_handled: 0, failures: 0]

  def start_link(id) do
    GenServer.start_link(__MODULE__, id)
  end

  def request(pid, method, url, opts \\ []) do
    GenServer.call(pid, {:request, method, url, opts}, 30_000)
  end

  @impl GenServer
  def init(id) do
    Process.flag(:trap_exit, true)
    {:ok, %__MODULE__{id: id, status: :idle}}
  end

  @impl GenServer
  def handle_call({:request, method, url, opts}, _from, state) do
    new_state = %{state | status: :busy}

    case perform_request(method, url, opts) do
      {:ok, response} ->
        final_state = %{new_state |
          status: :idle,
          requests_handled: state.requests_handled + 1
        }
        {:reply, {:ok, response}, final_state}

      {:error, reason} ->
        final_state = %{new_state |
          status: :idle,
          failures: state.failures + 1
        }
        {:reply, {:error, reason}, final_state}
    end
  end

  defp perform_request(_method, _url, opts) do
    # Simulate HTTP request
    fail_rate = Keyword.get(opts, :fail_rate, 0.1)

    if :rand.uniform() < fail_rate do
      {:error, :request_failed}
    else
      Process.sleep(100)
      {:ok, %{status: 200, body: "Success"}}
    end
  end
end
```

#### 2. Pool Supervisor with Restart Strategies

```elixir
defmodule HttpPoolSupervisor do
  use Supervisor

  def start_link(pool_size) do
    Supervisor.start_link(__MODULE__, pool_size, name: __MODULE__)
  end

  def checkout do
    # Get least loaded worker
    children = Supervisor.which_children(__MODULE__)

    workers = Enum.map(children, fn {_id, pid, _type, _modules} ->
      {:ok, state} = GenServer.call(pid, :get_state)
      {pid, state.requests_handled}
    end)

    {pid, _load} = Enum.min_by(workers, fn {_pid, load} -> load end)
    pid
  end

  @impl Supervisor
  def init(pool_size) do
    children = for i <- 1..pool_size do
      %{
        id: {:worker, i},
        start: {HttpWorker, :start_link, [i]},
        restart: :permanent,
        shutdown: 5_000
      }
    end

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10)
  end
end
```

#### 3. Circuit Breaker

```elixir
defmodule CircuitBreaker do
  use GenServer

  defstruct [
    :failure_threshold,
    :timeout,
    state: :closed,
    failures: 0,
    last_failure_time: nil
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def call(fun) do
    case GenServer.call(__MODULE__, :check) do
      :allow ->
        try do
          result = fun.()
          GenServer.cast(__MODULE__, :success)
          {:ok, result}
        catch
          _type, reason ->
            GenServer.cast(__MODULE__, :failure)
            {:error, reason}
        end

      :reject ->
        {:error, :circuit_open}
    end
  end

  @impl GenServer
  def init(opts) do
    state = %__MODULE__{
      failure_threshold: Keyword.get(opts, :failure_threshold, 5),
      timeout: Keyword.get(opts, :timeout, 60_000)
    }
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:check, _from, state) do
    case state.state do
      :closed ->
        {:reply, :allow, state}

      :open ->
        if should_try_reset?(state) do
          {:reply, :allow, %{state | state: :half_open}}
        else
          {:reply, :reject, state}
        end

      :half_open ->
        {:reply, :allow, state}
    end
  end

  @impl GenServer
  def handle_cast(:success, state) do
    {:noreply, %{state | state: :closed, failures: 0}}
  end

  def handle_cast(:failure, state) do
    new_failures = state.failures + 1
    new_state = %{state |
      failures: new_failures,
      last_failure_time: System.monotonic_time(:millisecond)
    }

    if new_failures >= state.failure_threshold do
      {:noreply, %{new_state | state: :open}}
    else
      {:noreply, new_state}
    end
  end

  defp should_try_reset?(state) do
    elapsed = System.monotonic_time(:millisecond) - state.last_failure_time
    elapsed >= state.timeout
  end
end
```

#### 4. Complete System with Supervision Tree

```elixir
defmodule HttpClientSystem do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def request(method, url, opts \\ []) do
    retry_count = Keyword.get(opts, :retries, 3)
    perform_with_retry(method, url, opts, retry_count)
  end

  defp perform_with_retry(_method, _url, _opts, 0) do
    {:error, :max_retries}
  end

  defp perform_with_retry(method, url, opts, retries) do
    CircuitBreaker.call(fn ->
      worker = HttpPoolSupervisor.checkout()
      HttpWorker.request(worker, method, url, opts)
    end)
    |> case do
      {:ok, {:ok, response}} -> {:ok, response}
      {:ok, {:error, _}} -> perform_with_retry(method, url, opts, retries - 1)
      {:error, :circuit_open} -> {:error, :circuit_open}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Supervisor
  def init(opts) do
    pool_size = Keyword.get(opts, :pool_size, 10)

    children = [
      {CircuitBreaker, [failure_threshold: 5, timeout: 60_000]},
      {HttpPoolSupervisor, pool_size}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### Bonus Features

1. **Telemetry:** Add metrics for success/failure rates
2. **Adaptive Pool Size:** Grow/shrink based on load
3. **Priority Queues:** High-priority requests first
4. **Request Coalescing:** Deduplicate identical requests
5. **Graceful Shutdown:** Finish in-flight requests

### Evaluation Criteria

**Fault Tolerance (35 points)**
- Proper supervision setup (10 pts)
- Restart strategies configured (10 pts)
- Process links correct (10 pts)
- Handles crashes gracefully (5 pts)

**Circuit Breaker (25 points)**
- State transitions work (10 pts)
- Timeout and reset logic (10 pts)
- Integration with pool (5 pts)

**Code Quality (20 points)**
- Clean supervision tree (10 pts)
- Proper error handling (5 pts)
- Good process organization (5 pts)

**Testing (20 points)**
- Tests for crash scenarios (10 pts)
- Circuit breaker tests (5 pts)
- Load testing (5 pts)

---

## Success Checklist

Before moving to Chapter 9, ensure you can:

- [ ] Understand the three error types (error, exit, throw)
- [ ] Use try/catch/rescue for error handling
- [ ] Know when to let processes crash vs catching errors
- [ ] Create process links with `spawn_link/1`
- [ ] Understand bidirectional link propagation
- [ ] Trap exits with `Process.flag(:trap_exit, true)`
- [ ] Create monitors with `Process.monitor/1`
- [ ] Understand monitor vs link trade-offs
- [ ] Start supervisors with `Supervisor.start_link/2`
- [ ] Write child specifications
- [ ] Understand `:one_for_one` strategy
- [ ] Configure restart options
- [ ] Know about max restart frequency
- [ ] Link entire process hierarchies
- [ ] Register processes for discovery after restarts

---

## Looking Ahead

Chapter 9 covers Supervision Trees, building on Chapter 8's foundations:
- Hierarchical supervision structures
- Multiple restart strategies (`:one_for_one`, `:one_for_all`, `:rest_for_one`)
- Fine-grained error isolation
- Building production-ready supervision hierarchies
- Dynamic supervisors for runtime children

Chapter 8's basics become the building blocks for sophisticated fault-tolerant architectures!
