# Chapter 6: Generic Server Processes (GenServer) - Learning Exercises

## Chapter Summary

Chapter 6 introduces GenServer, the OTP behaviour that eliminates boilerplate from server processes by providing a standardized framework for building stateful concurrent components. Through the behaviour pattern, GenServer handles message receiving, state management, and infinite recursion while developers implement callback functions (init/1, handle_call/3, handle_cast/2, handle_info/2) that define specific business logic. The chapter demonstrates building custom generic server abstractions before transitioning to GenServer, emphasizing that GenServer processes are OTP-compliant, production-ready components that integrate seamlessly with supervision trees and provide features like configurable timeouts, automatic crash propagation, and process registration.

---

## Concept Drills

### Drill 1: Understanding Behaviours

**Objective:** Grasp the behaviour/callback pattern that underpins GenServer.

**Task:** Analyze the relationship between generic and specific code:

```elixir
# Generic code (behaviour)
defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  defp loop(callback_module, state) do
    receive do
      {request, caller} ->
        {response, new_state} = callback_module.handle_call(request, state)
        send(caller, {:response, response})
        loop(callback_module, new_state)
    end
  end

  def call(pid, request) do
    send(pid, {request, self()})
    receive do
      {:response, response} -> response
    end
  end
end

# Specific implementation (callback module)
defmodule Counter do
  def init, do: 0

  def handle_call(:increment, state), do: {:ok, state + 1}
  def handle_call(:get, state), do: {state, state}
end
```

**Questions:**
1. What does the behaviour provide?
2. What does the callback module provide?
3. Where does each function execute (client vs server process)?
4. How does the behaviour know which functions to call?
5. Why is this pattern useful?

**Test it:**
```elixir
pid = ServerProcess.start(Counter)
ServerProcess.call(pid, :increment)  # => :ok
ServerProcess.call(pid, :get)        # => 1
```

---

### Drill 2: Basic GenServer Implementation

**Objective:** Create a simple GenServer from scratch.

**Task:** Implement a stack server using GenServer:

```elixir
defmodule Stack do
  use GenServer

  # Client API (runs in caller process)
  def start_link(initial_stack \\ []) do
    GenServer.start_link(__MODULE__, initial_stack, name: __MODULE__)
  end

  def push(item) do
    GenServer.cast(__MODULE__, {:push, item})
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  def peek do
    GenServer.call(__MODULE__, :peek)
  end

  # Server Callbacks (run in server process)
  @impl GenServer
  def init(initial_stack) do
    {:ok, initial_stack}
  end

  @impl GenServer
  def handle_cast({:push, item}, stack) do
    {:noreply, [item | stack]}
  end

  @impl GenServer
  def handle_call(:pop, _from, []) do
    {:reply, {:error, :empty}, []}
  end

  def handle_call(:pop, _from, [head | tail]) do
    {:reply, {:ok, head}, tail}
  end

  def handle_call(:peek, _from, []) do
    {:reply, {:error, :empty}, []}
  end

  def handle_call(:peek, _from, [head | _] = stack) do
    {:reply, {:ok, head}, stack}
  end
end
```

**Test Cases:**
```elixir
{:ok, _pid} = Stack.start_link()
Stack.push(1)
Stack.push(2)
Stack.push(3)
Stack.peek()         # => {:ok, 3}
Stack.pop()          # => {:ok, 3}
Stack.pop()          # => {:ok, 2}
Stack.peek()         # => {:ok, 1}
```

**Analysis Questions:**
1. Why use `cast` for push but `call` for pop/peek?
2. What does `@impl GenServer` do?
3. What's the second argument to `handle_call/3`?
4. When does `start_link` return?

---

### Drill 3: Call vs Cast

**Objective:** Understand when to use synchronous calls vs asynchronous casts.

**Task:** Implement a logger that uses both:

```elixir
defmodule Logger do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Async - doesn't need response
  def log(level, message) do
    GenServer.cast(__MODULE__, {:log, level, message, DateTime.utc_now()})
  end

  # Sync - needs to wait for file operation to complete
  def flush_to_disk(file_path) do
    GenServer.call(__MODULE__, {:flush, file_path})
  end

  # Sync - needs response
  def get_logs(filter_level \\ nil) do
    GenServer.call(__MODULE__, {:get_logs, filter_level})
  end

  # Sync - needs response
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @impl GenServer
  def init(_) do
    {:ok, []}
  end

  @impl GenServer
  def handle_cast({:log, level, message, timestamp}, logs) do
    entry = %{level: level, message: message, timestamp: timestamp}
    IO.puts("[#{level}] #{message}")
    {:noreply, [entry | logs]}
  end

  @impl GenServer
  def handle_call({:flush, file_path}, _from, logs) do
    result = File.write(file_path, :erlang.term_to_binary(logs))
    {:reply, result, logs}
  end

  def handle_call({:get_logs, nil}, _from, logs) do
    {:reply, Enum.reverse(logs), logs}
  end

  def handle_call({:get_logs, level}, _from, logs) do
    filtered = Enum.filter(logs, fn log -> log.level == level end)
    {:reply, Enum.reverse(filtered), logs}
  end

  def handle_call(:clear, _from, _logs) do
    {:reply, :ok, []}
  end
end
```

**Decision Guide:**
- Use **cast** when:
  - Caller doesn't need confirmation
  - Operation is idempotent
  - Performance is critical
  - Fire-and-forget semantics are acceptable

- Use **call** when:
  - Caller needs a return value
  - Operation must complete before continuing
  - Caller needs confirmation of success/failure
  - Order matters and you need synchronization

---

### Drill 4: Handle Info for External Messages

**Objective:** Handle messages not sent via call/cast.

**Task:** Create a periodic cleanup server:

```elixir
defmodule CacheServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def put(key, value, ttl_seconds) do
    GenServer.call(__MODULE__, {:put, key, value, ttl_seconds})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @impl GenServer
  def init(_) do
    # Schedule periodic cleanup
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:put, key, value, ttl}, _from, cache) do
    expiry = System.system_time(:second) + ttl
    new_cache = Map.put(cache, key, {value, expiry})
    {:reply, :ok, new_cache}
  end

  def handle_call({:get, key}, _from, cache) do
    case Map.get(cache, key) do
      {value, expiry} ->
        if System.system_time(:second) < expiry do
          {:reply, {:ok, value}, cache}
        else
          {:reply, :not_found, Map.delete(cache, key)}
        end

      nil ->
        {:reply, :not_found, cache}
    end
  end

  @impl GenServer
  def handle_info(:cleanup, cache) do
    now = System.system_time(:second)

    new_cache = cache
    |> Enum.filter(fn {_k, {_v, expiry}} -> expiry > now end)
    |> Enum.into(%{})

    IO.puts("Cleaned up #{map_size(cache) - map_size(new_cache)} expired entries")

    schedule_cleanup()
    {:noreply, new_cache}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, 10_000)  # Every 10 seconds
  end
end
```

**Key Points:**
- `handle_info/2` receives ANY message not matching call/cast format
- Used for timer messages, monitoring messages, etc.
- Returns `{:noreply, new_state}` like cast

---

### Drill 5: Process Registration

**Objective:** Use named processes for singleton servers.

**Task:** Compare registered vs unregistered approaches:

```elixir
# Unregistered (must pass PID everywhere)
defmodule UnregisteredCounter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, 0)
  end

  def increment(pid) do
    GenServer.call(pid, :increment)
  end

  @impl GenServer
  def init(initial), do: {:ok, initial}

  @impl GenServer
  def handle_call(:increment, _from, count) do
    {:reply, count + 1, count + 1}
  end
end

# Usage
{:ok, pid} = UnregisteredCounter.start_link()
UnregisteredCounter.increment(pid)  # Must pass PID

# Registered (access by name)
defmodule RegisteredCounter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def increment do
    GenServer.call(__MODULE__, :increment)
  end

  @impl GenServer
  def init(initial), do: {:ok, initial}

  @impl GenServer
  def handle_call(:increment, _from, count) do
    {:reply, count + 1, count + 1}
  end
end

# Usage
{:ok, _pid} = RegisteredCounter.start_link()
RegisteredCounter.increment()  # No PID needed!
```

**Registration Options:**
```elixir
# Local registration (current node only)
GenServer.start_link(MyServer, nil, name: :my_server)

# Via tuple (for custom registry)
GenServer.start_link(MyServer, nil, name: {:via, Registry, {MyRegistry, "key"}})

# Global registration (all connected nodes)
GenServer.start_link(MyServer, nil, name: {:global, :my_server})
```

---

### Drill 6: Initialization Patterns

**Objective:** Master different initialization approaches.

**Task:** Implement various init strategies:

```elixir
defmodule InitExamples do
  use GenServer

  # 1. Simple initialization
  def start_simple do
    GenServer.start_link(__MODULE__, :simple)
  end

  # 2. Initialization with parameters
  def start_with_params(initial_value) do
    GenServer.start_link(__MODULE__, {:with_params, initial_value})
  end

  # 3. Initialization that might fail
  def start_with_validation(value) do
    GenServer.start_link(__MODULE__, {:validate, value})
  end

  # 4. Deferred initialization (return quickly, init in handle_continue)
  def start_deferred do
    GenServer.start_link(__MODULE__, :deferred)
  end

  @impl GenServer
  def init(:simple) do
    {:ok, %{type: :simple, value: 0}}
  end

  def init({:with_params, initial_value}) do
    {:ok, %{type: :params, value: initial_value}}
  end

  def init({:validate, value}) when is_integer(value) and value > 0 do
    {:ok, %{type: :validated, value: value}}
  end

  def init({:validate, _invalid}) do
    {:stop, :invalid_initial_value}
  end

  def init(:deferred) do
    # Return immediately, do expensive setup in handle_continue
    {:ok, %{type: :deferred, value: nil}, {:continue, :load_data}}
  end

  @impl GenServer
  def handle_continue(:load_data, state) do
    # Expensive initialization here
    Process.sleep(3000)
    loaded_data = load_from_database()
    {:noreply, %{state | value: loaded_data}}
  end

  defp load_from_database, do: "expensive data"
end
```

**Test Different Scenarios:**
```elixir
# Success
{:ok, _pid} = InitExamples.start_simple()

# Success with params
{:ok, _pid} = InitExamples.start_with_params(42)

# Failure
{:error, :invalid_initial_value} = InitExamples.start_with_validation(-5)

# Deferred (returns quickly, initializes in background)
{:ok, pid} = InitExamples.start_deferred()  # Returns immediately
# Data loads in background via handle_continue
```

---

### Drill 7: Timeouts in Calls

**Objective:** Understand and configure call timeouts.

**Task:** Experiment with timeout behavior:

```elixir
defmodule SlowServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def fast_operation do
    GenServer.call(__MODULE__, :fast)
  end

  def slow_operation(delay_ms) do
    # Default 5 second timeout
    GenServer.call(__MODULE__, {:slow, delay_ms})
  end

  def slow_operation_with_timeout(delay_ms, timeout) do
    # Custom timeout
    GenServer.call(__MODULE__, {:slow, delay_ms}, timeout)
  end

  def infinite_wait(delay_ms) do
    # No timeout
    GenServer.call(__MODULE__, {:slow, delay_ms}, :infinity)
  end

  @impl GenServer
  def init(_), do: {:ok, nil}

  @impl GenServer
  def handle_call(:fast, _from, state) do
    {:reply, :done, state}
  end

  def handle_call({:slow, delay_ms}, _from, state) do
    Process.sleep(delay_ms)
    {:reply, :done, state}
  end
end
```

**Test Timeout Behaviors:**
```elixir
{:ok, _} = SlowServer.start_link()

# Fast - no problem
SlowServer.fast_operation()  # => :done

# Slow but within default 5s timeout
SlowServer.slow_operation(3000)  # => :done

# Too slow - will timeout and raise
try do
  SlowServer.slow_operation(6000)  # Exceeds 5s default
catch
  :exit, {:timeout, _} -> IO.puts("Timed out!")
end

# Slow but with custom timeout
SlowServer.slow_operation_with_timeout(6000, 10_000)  # => :done

# Very slow with infinite timeout
SlowServer.infinite_wait(20_000)  # => :done (waits full 20s)
```

---

## Integration Exercises

### Exercise 1: TodoServer with GenServer

**Objective:** Convert Chapter 4's TodoList to a GenServer.

**Concepts Reinforced:**
- GenServer callbacks (Chapter 6)
- TodoList abstraction (Chapter 4)
- State management (Chapters 4-6)
- Call/cast decisions (Chapter 6)

**Task:** Complete GenServer implementation of TodoServer:

```elixir
defmodule TodoServer do
  use GenServer

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def add_entry(entry) do
    GenServer.cast(__MODULE__, {:add_entry, entry})
  end

  def entries(date) do
    GenServer.call(__MODULE__, {:entries, date})
  end

  def update_entry(id, updater_fn) do
    GenServer.cast(__MODULE__, {:update_entry, id, updater_fn})
  end

  def delete_entry(id) do
    GenServer.cast(__MODULE__, {:delete_entry, id})
  end

  def all_entries do
    GenServer.call(__MODULE__, :all_entries)
  end

  ## Server Callbacks

  @impl GenServer
  def init(_) do
    {:ok, TodoList.new()}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, todo_list) do
    new_list = TodoList.add_entry(todo_list, entry)
    {:noreply, new_list}
  end

  def handle_cast({:update_entry, id, updater_fn}, todo_list) do
    new_list = TodoList.update_entry(todo_list, id, updater_fn)
    {:noreply, new_list}
  end

  def handle_cast({:delete_entry, id}, todo_list) do
    new_list = TodoList.delete_entry(todo_list, id)
    {:noreply, new_list}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, todo_list) do
    entries = TodoList.entries(todo_list, date)
    {:reply, entries, todo_list}
  end

  def handle_call(:all_entries, _from, todo_list) do
    all = TodoList.all_entries(todo_list)
    {:reply, all, todo_list}
  end
end
```

**Success Criteria:**
- All TodoList operations work
- Proper use of call vs cast
- State properly maintained
- Clean client API

---

### Exercise 2: Database Connection Pool

**Objective:** Build a connection pool using GenServer.

**Concepts Reinforced:**
- GenServer (Chapter 6)
- Process management (Chapter 5)
- State complexity (Chapter 4)
- Queuing (Chapter 5)

**Task:**

```elixir
defmodule DatabasePool do
  use GenServer

  defstruct [:connections, :waiting_callers, :max_connections]

  ## Client API

  def start_link(max_connections) do
    GenServer.start_link(__MODULE__, max_connections, name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout, :infinity)
  end

  def checkin(connection) do
    GenServer.cast(__MODULE__, {:checkin, connection})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  ## Server Callbacks

  @impl GenServer
  def init(max_connections) do
    # Create initial connections
    connections = for i <- 1..max_connections do
      create_connection(i)
    end

    state = %__MODULE__{
      connections: connections,
      waiting_callers: :queue.new(),
      max_connections: max_connections
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:checkout, from, state) do
    case state.connections do
      [conn | rest] ->
        # Connection available
        new_state = %{state | connections: rest}
        {:reply, {:ok, conn}, new_state}

      [] ->
        # No connections available, queue the caller
        new_waiting = :queue.in(from, state.waiting_callers)
        new_state = %{state | waiting_callers: new_waiting}
        {:noreply, new_state}
    end
  end

  def handle_call(:status, _from, state) do
    status = %{
      available: length(state.connections),
      waiting: :queue.len(state.waiting_callers),
      total: state.max_connections
    }
    {:reply, status, state}
  end

  @impl GenServer
  def handle_cast({:checkin, connection}, state) do
    case :queue.out(state.waiting_callers) do
      {{:value, caller}, new_waiting} ->
        # Someone is waiting, give them the connection
        GenServer.reply(caller, {:ok, connection})
        new_state = %{state | waiting_callers: new_waiting}
        {:noreply, new_state}

      {:empty, _} ->
        # No one waiting, add back to pool
        new_connections = [connection | state.connections]
        new_state = %{state | connections: new_connections}
        {:noreply, new_state}
    end
  end

  defp create_connection(id) do
    # Simulate connection creation
    {:conn, id}
  end
end
```

**Usage:**
```elixir
{:ok, _} = DatabasePool.start_link(3)

# Checkout connections
{:ok, conn1} = DatabasePool.checkout()
{:ok, conn2} = DatabasePool.checkout()
{:ok, conn3} = DatabasePool.checkout()

DatabasePool.status()
# => %{available: 0, waiting: 0, total: 3}

# Next checkout will wait
task = Task.async(fn -> DatabasePool.checkout() end)

DatabasePool.status()
# => %{available: 0, waiting: 1, total: 3}

# Return a connection - waiting task gets it immediately
DatabasePool.checkin(conn1)

{:ok, conn4} = Task.await(task)
# conn4 == conn1
```

---

### Exercise 3: Rate Limiter with GenServer

**Objective:** Implement token bucket rate limiter.

**Concepts Reinforced:**
- GenServer (Chapter 6)
- Time-based state (Chapter 5)
- handle_info for timers (Chapter 6)

**Task:**

```elixir
defmodule RateLimiter do
  use GenServer

  defstruct [
    :max_tokens,
    :current_tokens,
    :refill_rate,  # tokens per second
    :last_refill
  ]

  def start_link(max_tokens, refill_rate) do
    GenServer.start_link(__MODULE__, {max_tokens, refill_rate}, name: __MODULE__)
  end

  def allow?(cost \\ 1) do
    GenServer.call(__MODULE__, {:allow, cost})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl GenServer
  def init({max_tokens, refill_rate}) do
    # Schedule refills
    Process.send_after(self(), :refill, 1000)

    state = %__MODULE__{
      max_tokens: max_tokens,
      current_tokens: max_tokens,
      refill_rate: refill_rate,
      last_refill: System.monotonic_time(:second)
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:allow, cost}, _from, state) do
    if state.current_tokens >= cost do
      new_state = %{state | current_tokens: state.current_tokens - cost}
      {:reply, true, new_state}
    else
      {:reply, false, state}
    end
  end

  def handle_call(:status, _from, state) do
    {:reply, %{tokens: state.current_tokens, max: state.max_tokens}, state}
  end

  @impl GenServer
  def handle_info(:refill, state) do
    now = System.monotonic_time(:second)
    elapsed = now - state.last_refill

    tokens_to_add = elapsed * state.refill_rate
    new_tokens = min(state.current_tokens + tokens_to_add, state.max_tokens)

    new_state = %{state |
      current_tokens: new_tokens,
      last_refill: now
    }

    Process.send_after(self(), :refill, 1000)
    {:noreply, new_state}
  end
end
```

**Test:**
```elixir
# 10 tokens max, refill 2 per second
{:ok, _} = RateLimiter.start_link(10, 2)

# Use 5 tokens
RateLimiter.allow?(5)  # => true
RateLimiter.status()   # => %{tokens: 5, max: 10}

# Try to use 10 tokens - not enough
RateLimiter.allow?(10)  # => false

# Wait 3 seconds (6 tokens refilled)
Process.sleep(3000)
RateLimiter.status()   # => %{tokens: 10, max: 10}
```

---

## Capstone Project: Distributed Key-Value Store

### Project Description

Build a production-ready distributed key-value store with GenServer, supporting replication, expiration, and concurrent access patterns.

### Requirements

#### 1. Core KV Server

```elixir
defmodule KVStore.Server do
  use GenServer

  defstruct [
    :data,       # Map of key => {value, metadata}
    :replicas,   # List of replica PIDs
    :subscribers # List of change subscribers
  ]

  ## API

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def put(server \\ __MODULE__, key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl)
    replicate = Keyword.get(opts, :replicate, true)
    GenServer.call(server, {:put, key, value, ttl, replicate})
  end

  def get(server \\ __MODULE__, key) do
    GenServer.call(server, {:get, key})
  end

  def delete(server \\ __MODULE__, key) do
    GenServer.call(server, {:delete, key})
  end

  def keys(server \\ __MODULE__) do
    GenServer.call(server, :keys)
  end

  def subscribe(server \\ __MODULE__) do
    GenServer.call(server, {:subscribe, self()})
  end

  def add_replica(server \\ __MODULE__, replica_pid) do
    GenServer.call(server, {:add_replica, replica_pid})
  end

  ## Callbacks

  @impl GenServer
  def init(opts) do
    schedule_cleanup()

    state = %__MODULE__{
      data: %{},
      replicas: Keyword.get(opts, :replicas, []),
      subscribers: []
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:put, key, value, ttl, replicate}, _from, state) do
    metadata = %{
      inserted_at: System.system_time(:second),
      ttl: ttl
    }

    new_data = Map.put(state.data, key, {value, metadata})
    new_state = %{state | data: new_data}

    # Notify subscribers
    notify_subscribers(new_state.subscribers, {:put, key, value})

    # Replicate to other nodes
    if replicate do
      replicate_to_peers(state.replicas, {:put, key, value, ttl, false})
    end

    {:reply, :ok, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    case Map.get(state.data, key) do
      {value, metadata} ->
        if expired?(metadata) do
          new_data = Map.delete(state.data, key)
          {:reply, nil, %{state | data: new_data}}
        else
          {:reply, {:ok, value}, state}
        end

      nil ->
        {:reply, nil, state}
    end
  end

  def handle_call({:delete, key}, _from, state) do
    new_data = Map.delete(state.data, key)
    new_state = %{state | data: new_data}

    notify_subscribers(new_state.subscribers, {:delete, key})
    replicate_to_peers(state.replicas, {:delete, key})

    {:reply, :ok, new_state}
  end

  def handle_call(:keys, _from, state) do
    keys = Map.keys(state.data)
    {:reply, keys, state}
  end

  def handle_call({:subscribe, pid}, _from, state) do
    Process.monitor(pid)
    new_subscribers = [pid | state.subscribers]
    {:reply, :ok, %{state | subscribers: new_subscribers}}
  end

  def handle_call({:add_replica, replica_pid}, _from, state) do
    new_replicas = [replica_pid | state.replicas]
    {:reply, :ok, %{state | replicas: new_replicas}}
  end

  @impl GenServer
  def handle_info(:cleanup, state) do
    now = System.system_time(:second)

    new_data = state.data
    |> Enum.reject(fn {_k, {_v, metadata}} -> expired?(metadata, now) end)
    |> Enum.into(%{})

    schedule_cleanup()
    {:noreply, %{state | data: new_data}}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Remove crashed subscriber
    new_subscribers = List.delete(state.subscribers, pid)
    {:noreply, %{state | subscribers: new_subscribers}}
  end

  ## Private

  defp expired?(%{ttl: nil}), do: false
  defp expired?(%{ttl: ttl, inserted_at: inserted_at}) do
    expired?(ttl, inserted_at, System.system_time(:second))
  end

  defp expired?(%{ttl: nil}, _now), do: false
  defp expired?(%{ttl: ttl, inserted_at: inserted_at}, now) do
    inserted_at + ttl < now
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, 10_000)
  end

  defp notify_subscribers(subscribers, message) do
    Enum.each(subscribers, fn pid ->
      send(pid, {:kv_event, message})
    end)
  end

  defp replicate_to_peers(replicas, message) do
    Enum.each(replicas, fn replica ->
      GenServer.cast(replica, {:replicate, message})
    end)
  end
end
```

#### 2. Additional Features

**Transaction Support:**
```elixir
def transaction(server, fun) do
  GenServer.call(server, {:transaction, fun})
end
```

**Batch Operations:**
```elixir
def multi_get(server, keys) do
  GenServer.call(server, {:multi_get, keys})
end

def multi_put(server, kvs) do
  GenServer.call(server, {:multi_put, kvs})
end
```

**Statistics:**
```elixir
def stats(server) do
  GenServer.call(server, :stats)
end

# Should return:
# %{
#   keys: 100,
#   memory: 1_048_576,  # bytes
#   hits: 1000,
#   misses: 50,
#   replicas: 2
# }
```

### Bonus Challenges

1. **Persistence:** Save/load state to disk
2. **LRU Eviction:** Auto-remove least recently used
3. **Conflict Resolution:** Handle concurrent updates
4. **Partitioning:** Shard data across multiple servers
5. **Query Support:** Pattern matching on keys

### Evaluation Criteria

**GenServer Mastery (30 points)**
- Proper callback implementation (10 pts)
- Correct call/cast usage (10 pts)
- handle_info for timers (5 pts)
- Process lifecycle management (5 pts)

**Features (30 points)**
- Basic CRUD works (10 pts)
- TTL and expiration (10 pts)
- Replication (5 pts)
- Subscriptions (5 pts)

**Code Quality (25 points)**
- Clean API design (10 pts)
- Proper state management (10 pts)
- Error handling (5 pts)

**Testing (15 points)**
- Comprehensive tests (10 pts)
- Concurrent access tests (5 pts)

---

## Success Checklist

Before moving to Chapter 7, ensure you can:

- [ ] Understand the behaviour/callback pattern
- [ ] Implement GenServer callbacks
- [ ] Use `use GenServer` correctly
- [ ] Know when to use call vs cast
- [ ] Implement `init/1` properly
- [ ] Handle synchronous requests with `handle_call/3`
- [ ] Handle asynchronous requests with `handle_cast/2`
- [ ] Handle plain messages with `handle_info/2`
- [ ] Return correct tuples from callbacks
- [ ] Register processes with `name:` option
- [ ] Use `@impl GenServer` for compile-time checks
- [ ] Configure call timeouts
- [ ] Stop servers gracefully
- [ ] Understand GenServer process lifecycle
- [ ] Know what OTP-compliant means

---

## Looking Ahead

Chapter 7 builds a complete concurrent system using multiple GenServers working together, demonstrating:
- Multi-process architectures
- Process organization patterns
- Building complex systems from simple components
- Using Mix for proper project structure

Everything you've learned about GenServer becomes the building block for real applications!
