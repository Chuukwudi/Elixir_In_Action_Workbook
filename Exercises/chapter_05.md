# Chapter 5: Concurrency Primitives - Learning Exercises

## Chapter Summary

Chapter 5 introduces BEAM's concurrency model, where lightweight processes serve as the fundamental unit of concurrency, enabling scalability through parallelization and fault tolerance through isolation. Processes communicate exclusively through asynchronous message passing with deep-copied data, maintaining complete isolation while allowing cooperation through well-defined protocols. Server processes use endless tail recursion to maintain long-running state and handle requests sequentially, providing synchronization points while the BEAM scheduler efficiently manages millions of processes across available CPU cores through preemptive multitasking.

---

## Concept Drills

### Drill 1: Creating and Spawning Processes

**Objective:** Understand process creation with `spawn/1` and process identification.

**Task:** Experiment with basic process creation:

```elixir
# 1. Create a process that prints a message
spawn(fn -> IO.puts("Hello from process #{inspect(self())}") end)

# 2. Create multiple processes
Enum.each(1..5, fn i ->
  spawn(fn ->
    IO.puts("Process #{i}: #{inspect(self())}")
  end)
end)

# 3. Verify processes run concurrently
Enum.each(1..3, fn i ->
  spawn(fn ->
    Process.sleep(1000)
    IO.puts("Process #{i} done after 1 second")
  end)
end)
# All three should print at approximately the same time

# 4. Pass data to spawned processes via closure
data = %{name: "Alice", age: 30}
spawn(fn ->
  IO.puts("Received data: #{inspect(data)}")
end)
```

**Questions to Answer:**
1. What does `spawn/1` return?
2. How long does `spawn/1` take to return?
3. What is the PID and why is it important?
4. How is data passed to the spawned process?
5. What happens to the spawned process after its function completes?

**Expected Behavior:**
- `spawn/1` returns immediately with a PID
- Multiple processes print in non-deterministic order
- Processes don't block the caller

---

### Drill 2: Message Passing Basics

**Objective:** Master sending and receiving messages between processes.

**Task:** Practice asynchronous message passing:

```elixir
# 1. Send message to self
send(self(), {:hello, "world"})

receive do
  {:hello, msg} -> IO.puts("Received: #{msg}")
end

# 2. Send multiple messages
send(self(), :first)
send(self(), :second)
send(self(), :third)

# Receive them one by one
receive do msg -> IO.inspect(msg) end
receive do msg -> IO.inspect(msg) end
receive do msg -> IO.inspect(msg) end

# 3. Pattern match on messages
send(self(), {:sum, 10, 20})
send(self(), {:product, 5, 6})

receive do
  {:sum, a, b} -> IO.puts("Sum: #{a + b}")
end

receive do
  {:product, a, b} -> IO.puts("Product: #{a * b}")
end

# 4. Use after clause
receive do
  :some_message -> IO.puts("Got message")
after
  1000 -> IO.puts("Timeout after 1 second")
end
```

**Expected Output:**
- Messages arrive in FIFO order
- Pattern matching selects appropriate messages
- Unmatched messages stay in mailbox
- After clause prevents indefinite blocking

---

### Drill 3: Synchronous Request-Response

**Objective:** Implement synchronous communication using asynchronous messages.

**Task:** Build request-response pattern:

```elixir
# Helper process that echoes messages back
echo_server = spawn(fn ->
  receive do
    {caller_pid, message} ->
      send(caller_pid, {:response, message})
  end
end)

# Send request and wait for response
send(echo_server, {self(), "Hello"})

response = receive do
  {:response, msg} -> msg
after
  5000 -> :timeout
end

IO.puts("Got response: #{response}")
```

**Now create a function that wraps this pattern:**

```elixir
defmodule SyncClient do
  def call(server_pid, request) do
    # Send request with caller PID
    # Wait for response
    # Return response or timeout
  end
end
```

**Success Criteria:**
- Caller blocks until response arrives
- Timeout prevents indefinite waiting
- Pattern matches ensure correct response

---

### Drill 4: Concurrent Task Execution

**Objective:** Use processes to parallelize independent work.

**Task:** Implement parallel execution:

```elixir
defmodule ParallelTasks do
  def run_concurrently(tasks) do
    # tasks is a list of functions to execute
    # Spawn a process for each task
    # Collect all results
  end
end

# Test it
tasks = [
  fn -> Process.sleep(1000); "Task 1 done" end,
  fn -> Process.sleep(1000); "Task 2 done" end,
  fn -> Process.sleep(1000); "Task 3 done" end
]

# Should take ~1 second, not 3
results = ParallelTasks.run_concurrently(tasks)
IO.inspect(results)
```

**Implementation Hint:**
```elixir
def run_concurrently(tasks) do
  caller = self()

  # Spawn workers
  Enum.each(tasks, fn task ->
    spawn(fn ->
      result = task.()
      send(caller, {:result, result})
    end)
  end)

  # Collect results
  Enum.map(tasks, fn _ ->
    receive do
      {:result, result} -> result
    end
  end)
end
```

---

### Drill 5: Basic Server Process Loop

**Objective:** Implement an endless tail-recursive server loop.

**Task:** Create a simple counter server:

```elixir
defmodule Counter do
  def start do
    spawn(fn -> loop(0) end)
  end

  defp loop(current_value) do
    receive do
      {:increment, caller} ->
        send(caller, {:ok, current_value + 1})
        loop(current_value + 1)

      {:get, caller} ->
        send(caller, {:ok, current_value})
        loop(current_value)
    end
  end

  # Interface functions
  def increment(pid) do
    send(pid, {:increment, self()})
    receive do
      {:ok, value} -> value
    end
  end

  def get(pid) do
    send(pid, {:get, self()})
    receive do
      {:ok, value} -> value
    end
  end
end
```

**Test it:**
```elixir
counter = Counter.start()
Counter.increment(counter)  # => 1
Counter.increment(counter)  # => 2
Counter.get(counter)         # => 2
```

**Questions:**
1. Why doesn't the loop function cause a stack overflow?
2. What happens if we send an unexpected message?
3. How is state maintained between loop iterations?

---

### Drill 6: Stateful Server Process

**Objective:** Maintain and modify complex state in a server process.

**Task:** Build a key-value store server:

```elixir
defmodule KeyValueStore do
  def start do
    spawn(fn -> loop(%{}) end)
  end

  defp loop(state) do
    new_state = receive do
      {:put, key, value} ->
        # Return new state with key-value added

      {:get, key, caller} ->
        # Send value to caller
        # Return unchanged state

      {:delete, key} ->
        # Return state without key

      {:keys, caller} ->
        # Send all keys to caller
        # Return unchanged state
    end

    loop(new_state)
  end

  # Implement interface functions
  def put(pid, key, value), do: # ...
  def get(pid, key), do: # ...
  def delete(pid, key), do: # ...
  def keys(pid), do: # ...
end
```

**Test Cases:**
```elixir
store = KeyValueStore.start()
KeyValueStore.put(store, :name, "Alice")
KeyValueStore.put(store, :age, 30)
KeyValueStore.get(store, :name)      # => "Alice"
KeyValueStore.keys(store)            # => [:name, :age]
KeyValueStore.delete(store, :age)
KeyValueStore.keys(store)            # => [:name]
```

---

### Drill 7: Process Registration

**Objective:** Use named processes for easier process discovery.

**Task:** Create a registered singleton server:

```elixir
defmodule GlobalCounter do
  @name :global_counter

  def start do
    pid = spawn(fn -> loop(0) end)
    Process.register(pid, @name)
    :ok
  end

  defp loop(count) do
    # Handle messages
  end

  def increment do
    send(@name, {:increment, self()})
    receive do
      {:ok, new_value} -> new_value
    end
  end

  def get do
    # Implement
  end
end
```

**Test:**
```elixir
GlobalCounter.start()
GlobalCounter.increment()  # No need to pass PID
GlobalCounter.increment()
GlobalCounter.get()        # => 2
```

**Questions:**
1. What happens if you try to register two processes with the same name?
2. What happens if the registered process crashes?
3. Can you register a process with a string name?

---

### Drill 8: Async vs Sync Operations

**Objective:** Understand when to use asynchronous vs synchronous messaging.

**Task:** Implement a logger with both async and sync modes:

```elixir
defmodule Logger do
  def start do
    spawn(fn -> loop([]) end)
  end

  defp loop(logs) do
    receive do
      {:log, message} ->
        # Async: just log and continue
        IO.puts("[LOG] #{message}")
        loop([message | logs])

      {:get_logs, caller} ->
        # Sync: send logs back
        send(caller, {:logs, Enum.reverse(logs)})
        loop(logs)

      {:clear, caller} ->
        # Sync: clear and confirm
        send(caller, :ok)
        loop([])
    end
  end

  # Async - doesn't wait
  def log(pid, message) do
    send(pid, {:log, message})
  end

  # Sync - waits for response
  def get_logs(pid) do
    send(pid, {:get_logs, self()})
    receive do
      {:logs, logs} -> logs
    end
  end

  def clear(pid) do
    send(pid, {:clear, self()})
    receive do
      :ok -> :ok
    end
  end
end
```

**Analysis Questions:**
1. Why is `log/2` async?
2. Why is `get_logs/1` sync?
3. What are the performance implications?

---

### Drill 9: Process Pooling

**Objective:** Understand how to create and use a pool of worker processes.

**Task:** Create a simple worker pool:

```elixir
defmodule WorkerPool do
  def start_pool(size) do
    Enum.map(1..size, fn _ ->
      spawn(fn -> worker_loop() end)
    end)
  end

  defp worker_loop do
    receive do
      {caller, work_fn} ->
        result = work_fn.()
        send(caller, {:result, result})
    end
    worker_loop()
  end

  def execute(pool, work_fn) do
    # Select random worker
    worker = Enum.random(pool)
    send(worker, {self(), work_fn})

    receive do
      {:result, result} -> result
    end
  end
end
```

**Test:**
```elixir
pool = WorkerPool.start_pool(10)

# Execute work on random workers
Enum.each(1..5, fn i ->
  WorkerPool.execute(pool, fn ->
    Process.sleep(1000)
    "Task #{i} completed"
  end)
end)
```

---

## Integration Exercises

### Exercise 1: Parallel Data Processing Pipeline

**Objective:** Combine processes with data transformation pipelines.

**Concepts Reinforced:**
- Process spawning (Chapter 5)
- Message passing (Chapter 5)
- Data pipelines (Chapters 2 & 3)
- Enum operations (Chapter 3)

**Task:** Build a parallel map-reduce system:

```elixir
defmodule ParallelMapReduce do
  def map_reduce(data, mapper, reducer, initial_acc) do
    # 1. Spawn processes to map each data item
    # 2. Collect all mapped results
    # 3. Reduce the results
  end

  def parallel_map(data, mapper) do
    caller = self()

    # Spawn mapper for each item
    data
    |> Enum.with_index()
    |> Enum.each(fn {item, index} ->
      spawn(fn ->
        result = mapper.(item)
        send(caller, {:mapped, index, result})
      end)
    end)

    # Collect results in order
    data
    |> Enum.with_index()
    |> Enum.map(fn {_, index} ->
      receive do
        {:mapped, ^index, result} -> result
      end
    end)
  end
end
```

**Test Cases:**
```elixir
# Parallel sum of squares
data = 1..100
result = ParallelMapReduce.map_reduce(
  data,
  fn x -> x * x end,     # mapper
  fn acc, x -> acc + x end,  # reducer
  0                          # initial
)

# Parallel word count
text = "the quick brown fox jumps over the lazy dog the fox"
words = String.split(text)

word_counts = ParallelMapReduce.map_reduce(
  words,
  fn word -> {word, 1} end,
  fn acc, {word, count} ->
    Map.update(acc, word, count, &(&1 + count))
  end,
  %{}
)
```

---

### Exercise 2: Todo Server with Concurrency

**Objective:** Convert TodoList abstraction to concurrent server.

**Concepts Reinforced:**
- TodoList from Chapter 4
- Server processes (Chapter 5)
- Message protocols (Chapter 5)
- State management (Chapter 5)

**Task:** Implement concurrent TodoServer:

```elixir
defmodule TodoServer do
  def start do
    spawn(fn -> loop(TodoList.new()) end)
  end

  defp loop(todo_list) do
    new_todo_list = receive do
      {:add_entry, entry, caller} ->
        # Add entry and send confirmation

      {:entries, date, caller} ->
        # Send entries for date

      {:update_entry, entry_id, updater_fn, caller} ->
        # Update and confirm

      {:delete_entry, entry_id, caller} ->
        # Delete and confirm
    end

    loop(new_todo_list)
  end

  # Interface functions
  def add_entry(pid, entry), do: # sync
  def entries(pid, date), do: # sync
  def update_entry(pid, id, updater), do: # sync
  def delete_entry(pid, id), do: # sync
end
```

**Success Criteria:**
- All TodoList operations work correctly
- State persists across operations
- Multiple clients can interact with same server
- Server handles requests sequentially

---

### Exercise 3: Concurrent Cache with TTL

**Objective:** Build a cache server with time-to-live expiration.

**Concepts Reinforced:**
- Server processes (Chapter 5)
- Maps and state (Chapters 2 & 4)
- Process timing (Chapter 5)

**Task:**

```elixir
defmodule CacheServer do
  defstruct data: %{}, expiry: %{}

  def start do
    spawn(fn ->
      # Start expiration checker
      schedule_cleanup()
      loop(%CacheServer{})
    end)
  end

  defp loop(state) do
    new_state = receive do
      {:put, key, value, ttl, caller} ->
        # Store value with expiration time
        expiry_time = System.monotonic_time(:second) + ttl
        state
        |> put_in([:data, key], value)
        |> put_in([:expiry, key], expiry_time)
        |> tap(fn _ -> send(caller, :ok) end)

      {:get, key, caller} ->
        # Check if expired
        now = System.monotonic_time(:second)

        case {state.data[key], state.expiry[key]} do
          {value, exp_time} when not is_nil(value) and exp_time > now ->
            send(caller, {:ok, value})
          _ ->
            send(caller, :not_found)
        end
        state

      :cleanup ->
        # Remove expired entries
        schedule_cleanup()
        cleanup_expired(state)
    end

    loop(new_state)
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, 5000)
  end

  defp cleanup_expired(state) do
    now = System.monotonic_time(:second)

    valid_keys = state.expiry
    |> Enum.filter(fn {_key, exp_time} -> exp_time > now end)
    |> Enum.map(fn {key, _} -> key end)

    %CacheServer{
      data: Map.take(state.data, valid_keys),
      expiry: Map.take(state.expiry, valid_keys)
    }
  end

  # Interface
  def put(pid, key, value, ttl) do
    send(pid, {:put, key, value, ttl, self()})
    receive do :ok -> :ok end
  end

  def get(pid, key) do
    send(pid, {:get, key, self()})
    receive do
      {:ok, value} -> {:ok, value}
      :not_found -> :not_found
    end
  end
end
```

**Test:**
```elixir
cache = CacheServer.start()
CacheServer.put(cache, :user_1, %{name: "Alice"}, 10)
CacheServer.get(cache, :user_1)  # => {:ok, %{name: "Alice"}}

# Wait 11 seconds
Process.sleep(11_000)
CacheServer.get(cache, :user_1)  # => :not_found
```

---

### Exercise 4: Concurrent Job Queue

**Objective:** Build a job queue with worker pool.

**Concepts Reinforced:**
- Multiple processes (Chapter 5)
- Process coordination (Chapter 5)
- Queues and state (Chapters 2-4)

**Task:**

```elixir
defmodule JobQueue do
  defstruct queue: :queue.new(), workers: [], max_workers: 5

  def start(max_workers \\ 5) do
    spawn(fn ->
      state = %JobQueue{max_workers: max_workers}
      loop(state)
    end)
  end

  defp loop(state) do
    new_state = receive do
      {:enqueue, job, caller} ->
        # Add job to queue
        # Try to start worker if available
        send(caller, :ok)
        state
        |> update_in([:queue], &:queue.in(job, &1))
        |> maybe_start_worker()

      {:worker_done, worker_pid} ->
        # Remove worker from workers list
        # Try to start next job
        state
        |> update_in([:workers], &List.delete(&1, worker_pid))
        |> maybe_start_worker()

      {:status, caller} ->
        # Return queue size and worker count
        send(caller, {
          :status,
          :queue.len(state.queue),
          length(state.workers)
        })
        state
    end

    loop(new_state)
  end

  defp maybe_start_worker(state) do
    cond do
      :queue.is_empty(state.queue) ->
        state

      length(state.workers) >= state.max_workers ->
        state

      true ->
        {{:value, job}, new_queue} = :queue.out(state.queue)
        worker_pid = spawn_worker(job)

        %{state |
          queue: new_queue,
          workers: [worker_pid | state.workers]
        }
    end
  end

  defp spawn_worker(job) do
    queue_pid = self()

    spawn(fn ->
      job.()
      send(queue_pid, {:worker_done, self()})
    end)
  end

  # Interface
  def enqueue(pid, job) do
    send(pid, {:enqueue, job, self()})
    receive do :ok -> :ok end
  end

  def status(pid) do
    send(pid, {:status, self()})
    receive do
      {:status, queue_size, worker_count} ->
        %{queue_size: queue_size, active_workers: worker_count}
    end
  end
end
```

**Test:**
```elixir
queue = JobQueue.start(3)

# Enqueue 10 jobs
Enum.each(1..10, fn i ->
  JobQueue.enqueue(queue, fn ->
    Process.sleep(2000)
    IO.puts("Job #{i} completed")
  end)
end)

# Check status
JobQueue.status(queue)
# => %{queue_size: 7, active_workers: 3}
```

---

### Exercise 5: Distributed Word Counter

**Objective:** Count words in multiple files using process pool.

**Concepts Reinforced:**
- File I/O (Chapter 3)
- Streams (Chapter 3)
- Process pools (Chapter 5)
- Data aggregation (Chapter 3)

**Task:**

```elixir
defmodule WordCounter do
  def count_words_in_files(file_paths, num_workers \\ 4) do
    # 1. Start worker pool
    # 2. Distribute files to workers
    # 3. Each worker counts words in its files
    # 4. Aggregate results

    caller = self()

    # Distribute work
    file_paths
    |> Enum.with_index()
    |> Enum.each(fn {file_path, index} ->
      spawn(fn ->
        word_count = count_words_in_file(file_path)
        send(caller, {:result, index, word_count})
      end)
    end)

    # Collect and merge results
    file_paths
    |> Enum.with_index()
    |> Enum.map(fn {_, index} ->
      receive do
        {:result, ^index, word_count} -> word_count
      end
    end)
    |> Enum.reduce(%{}, fn counts, acc ->
      Map.merge(acc, counts, fn _k, v1, v2 -> v1 + v2 end)
    end)
  end

  defp count_words_in_file(file_path) do
    file_path
    |> File.stream!()
    |> Stream.flat_map(&String.split/1)
    |> Enum.reduce(%{}, fn word, acc ->
      Map.update(acc, String.downcase(word), 1, &(&1 + 1))
    end)
  end
end
```

---

## Capstone Project: Concurrent HTTP Request Pool

### Project Description

Build a production-ready concurrent HTTP request handler that manages a pool of worker processes, implements rate limiting, handles retries, and provides request/response caching.

### Requirements

#### 1. Worker Pool Manager

```elixir
defmodule HttpPool do
  defstruct [
    :max_workers,
    :available_workers,
    :busy_workers,
    :request_queue,
    :rate_limiter,
    :cache
  ]

  def start_link(opts \\ []) do
    max_workers = Keyword.get(opts, :max_workers, 10)
    requests_per_second = Keyword.get(opts, :rate_limit, 100)

    # Start the pool manager
    # Initialize worker pool
    # Start rate limiter
    # Start cache server
  end

  def request(pool_pid, method, url, headers \\ [], body \\ "") do
    # Check cache
    # Check rate limit
    # Queue request or assign to worker
    # Return response
  end
end
```

#### 2. Worker Process

```elixir
defmodule HttpPool.Worker do
  def start_link(pool_pid) do
    spawn(fn -> loop(pool_pid, :available) end)
  end

  defp loop(pool_pid, state) do
    receive do
      {:execute, request_id, method, url, headers, body, caller} ->
        # Mark self as busy
        send(pool_pid, {:worker_busy, self()})

        # Execute HTTP request
        response = execute_request(method, url, headers, body)

        # Send response
        send(caller, {:response, request_id, response})

        # Mark self as available
        send(pool_pid, {:worker_available, self()})
        loop(pool_pid, :available)
    end
  end

  defp execute_request(method, url, headers, body) do
    # Simulate HTTP request
    # In real implementation, use HTTPoison or similar
    Process.sleep(100)
    {:ok, %{status: 200, body: "Response from #{url}"}}
  end
end
```

#### 3. Rate Limiter

```elixir
defmodule HttpPool.RateLimiter do
  def start_link(requests_per_second) do
    spawn(fn ->
      loop(%{
        limit: requests_per_second,
        window_start: System.monotonic_time(:second),
        count: 0,
        waiting: :queue.new()
      })
    end)
  end

  defp loop(state) do
    new_state = receive do
      {:check, caller} ->
        # Check if request can proceed
        # If yes, increment count and allow
        # If no, queue the request
        handle_rate_check(state, caller)

      :tick ->
        # Reset window
        # Process waiting requests
        reset_window(state)
    after
      1000 -> reset_window(state)
    end

    loop(new_state)
  end
end
```

#### 4. Cache Server

```elixir
defmodule HttpPool.Cache do
  def start_link do
    spawn(fn ->
      loop(%{
        data: %{},
        access_times: %{},
        max_size: 1000
      })
    end)
  end

  defp loop(state) do
    new_state = receive do
      {:get, key, caller} ->
        case Map.get(state.data, key) do
          nil -> send(caller, :miss)
          value -> send(caller, {:hit, value})
        end
        state

      {:put, key, value} ->
        # Implement LRU eviction
        put_with_eviction(state, key, value)
    end

    loop(new_state)
  end
end
```

#### 5. Request Queue

```elixir
defmodule HttpPool.RequestQueue do
  def start_link do
    spawn(fn -> loop(:queue.new()) end)
  end

  defp loop(queue) do
    new_queue = receive do
      {:enqueue, request, caller} ->
        send(caller, :ok)
        :queue.in(request, queue)

      {:dequeue, caller} ->
        case :queue.out(queue) do
          {{:value, request}, new_q} ->
            send(caller, {:ok, request})
            new_q
          {:empty, new_q} ->
            send(caller, :empty)
            new_q
        end

      {:size, caller} ->
        send(caller, {:size, :queue.len(queue)})
        queue
    end

    loop(new_queue)
  end
end
```

### Complete Integration

```elixir
defmodule HttpPool.Manager do
  def start_link(opts) do
    spawn(fn ->
      state = initialize_pool(opts)
      loop(state)
    end)
  end

  defp loop(state) do
    new_state = receive do
      {:request, request_id, method, url, headers, body, caller} ->
        handle_request(state, request_id, method, url, headers, body, caller)

      {:worker_available, worker_pid} ->
        # Move worker to available list
        # Try to assign queued work
        handle_worker_available(state, worker_pid)

      {:worker_busy, worker_pid} ->
        # Move worker to busy list
        move_to_busy(state, worker_pid)

      {:stats, caller} ->
        send(caller, get_stats(state))
        state
    end

    loop(new_state)
  end
end
```

### Usage Example

```elixir
# Start the pool
{:ok, pool} = HttpPool.start_link(
  max_workers: 20,
  rate_limit: 100,  # requests per second
  cache_size: 1000
)

# Make requests
tasks = Enum.map(1..1000, fn i ->
  Task.async(fn ->
    HttpPool.request(
      pool,
      :get,
      "https://api.example.com/data/#{i}",
      [{"Authorization", "Bearer token"}]
    )
  end)
end)

# Wait for all responses
responses = Task.await_many(tasks, 30_000)

# Get statistics
stats = HttpPool.stats(pool)
IO.inspect(stats)
# %{
#   total_requests: 1000,
#   successful: 980,
#   failed: 20,
#   cache_hits: 450,
#   cache_misses: 550,
#   average_response_time: 120,  # ms
#   active_workers: 15,
#   queued_requests: 0
# }
```

### Bonus Challenges

1. **Retry Logic:** Implement exponential backoff
2. **Circuit Breaker:** Stop sending to failing endpoints
3. **Request Timeout:** Configurable per-request timeouts
4. **Connection Pooling:** Reuse HTTP connections
5. **Metrics:** Track detailed performance metrics
6. **Health Checks:** Periodic worker health verification

### Evaluation Criteria

**Concurrency (30 points)**
- Correct process spawning and management (10 pts)
- Message passing protocols (10 pts)
- State management in processes (10 pts)

**Architecture (25 points)**
- Clean separation of concerns (10 pts)
- Worker pool implementation (10 pts)
- Queue management (5 pts)

**Features (25 points)**
- Rate limiting works correctly (10 pts)
- Cache implementation (10 pts)
- Error handling (5 pts)

**Code Quality (20 points)**
- Clean, readable code (10 pts)
- Proper interface functions (5 pts)
- Documentation (5 pts)

---

## Success Checklist

Before moving to Chapter 6, ensure you can:

- [ ] Create processes with `spawn/1`
- [ ] Understand PIDs and their role
- [ ] Send messages with `send/2`
- [ ] Receive messages with `receive/do`
- [ ] Use pattern matching in receive blocks
- [ ] Implement timeouts with `after` clause
- [ ] Build synchronous request-response patterns
- [ ] Create server processes with endless recursion
- [ ] Maintain state in process loop arguments
- [ ] Register processes with names
- [ ] Understand why tail recursion is critical
- [ ] Build stateful servers
- [ ] Handle multiple message types
- [ ] Understand process isolation
- [ ] Know about message deep copying
- [ ] Understand scheduler behavior
- [ ] Recognize process bottlenecks
- [ ] Use process pools for parallelization

---

## Looking Ahead

Chapter 6 will introduce GenServer, which abstracts away the manual server process patterns you've learned, providing:
- Standardized callback interface
- Built-in synchronous/asynchronous calls
- Proper initialization and termination
- Integration with OTP supervision

Everything you learned about processes and server loops in Chapter 5 is the foundation GenServer builds upon!
