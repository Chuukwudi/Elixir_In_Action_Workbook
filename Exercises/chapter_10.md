# Chapter 10: Beyond GenServer - Learning Exercises

## Chapter Summary

Chapter 10 introduces three powerful OTP abstractions that complement GenServer: Task for running one-off concurrent computations (with both awaited and non-awaited variants), Agent for simplified state management without the ceremony of GenServer callbacks, and ETS (Erlang Term Storage) tables for high-performance shared in-memory storage. While GenServer remains the foundation for most server processes, Tasks excel at parallel job execution, Agents reduce boilerplate for simple state holders, and ETS tables provide exceptional performance for read-heavy shared data structures by bypassing process serialization and enabling true concurrent access with minimal garbage collection overhead.

---

## Concept Drills

### Drill 1: Awaited Tasks Basics

**Objective:** Understand Task.async/await for concurrent computations.

**Task:** Run multiple independent computations in parallel:

```elixir
defmodule TaskDrill do
  def sequential_work do
    results = for i <- 1..5 do
      slow_computation(i)
    end

    IO.inspect(results, label: "Sequential results")
  end

  def parallel_work do
    tasks = for i <- 1..5 do
      Task.async(fn -> slow_computation(i) end)
    end

    results = Enum.map(tasks, &Task.await/1)
    IO.inspect(results, label: "Parallel results")
  end

  defp slow_computation(n) do
    Process.sleep(1000)
    n * n
  end
end
```

**Exercises:**
1. Run `sequential_work/0` and time it
2. Run `parallel_work/0` and time it
3. What's the speedup from parallelization?
4. Modify to handle timeout: use `Task.await(task, 500)`
5. What happens if a task crashes?

**Expected Behavior:**
```elixir
# Sequential takes ~5 seconds
:timer.tc(fn -> TaskDrill.sequential_work() end)
# => {5_000_000+, :ok}

# Parallel takes ~1 second
:timer.tc(fn -> TaskDrill.parallel_work() end)
# => {1_000_000+, :ok}
```

**Key Insights:**
- Tasks run in separate processes
- `Task.async/1` returns immediately
- `Task.await/1` blocks until result arrives
- Default timeout is 5 seconds
- Task crash takes down caller (linked)

---

### Drill 2: Non-Awaited Tasks

**Objective:** Use Task.start_link for fire-and-forget jobs.

**Task:** Implement a metrics reporter:

```elixir
defmodule MetricsReporter do
  use Task

  def start_link(_arg) do
    Task.start_link(fn -> loop() end)
  end

  defp loop do
    report_metrics()
    Process.sleep(5000)
    loop()
  end

  defp report_metrics do
    metrics = %{
      memory: :erlang.memory(:total),
      processes: :erlang.system_info(:process_count),
      timestamp: System.system_time(:second)
    }

    IO.inspect(metrics, label: "System Metrics")
  end
end
```

**Exercises:**
1. Add to a supervision tree
2. What happens if the task crashes?
3. How is this different from GenServer?
4. Why use `use Task`?
5. Implement graceful shutdown

**Usage:**
```elixir
# In a supervisor
children = [
  MetricsReporter,
  # other children...
]

Supervisor.start_link(children, strategy: :one_for_one)
```

**Key Points:**
- `Task.start_link/1` doesn't send results back
- Perfect for periodic jobs
- Simpler than GenServer for non-responsive tasks
- `use Task` provides child_spec/1

---

### Drill 3: Dynamic Task Supervision

**Objective:** Supervise tasks started on demand.

**Task:** Create a job processor:

```elixir
defmodule JobProcessor do
  def start_link do
    Task.Supervisor.start_link(name: __MODULE__)
  end

  def process_async(job_data) do
    Task.Supervisor.start_child(
      __MODULE__,
      fn -> perform_job(job_data) end
    )
  end

  defp perform_job(data) do
    IO.puts("Processing job: #{inspect(data)}")
    Process.sleep(2000)
    IO.puts("Job complete: #{inspect(data)}")
    {:ok, "Result for #{data}"}
  end
end
```

**Exercises:**
1. Start the task supervisor
2. Launch 10 jobs concurrently
3. What happens if a job crashes?
4. Does it affect other jobs?
5. Compare to DynamicSupervisor

**Test:**
```elixir
JobProcessor.start_link()

for i <- 1..10 do
  JobProcessor.process_async("job_#{i}")
end

# All 10 jobs run concurrently
# Each takes 2 seconds
# Total time: ~2 seconds
```

**Differences from DynamicSupervisor:**
- Task.Supervisor specialized for tasks
- Simpler API for one-off computations
- Tasks are temporary by default

---

### Drill 4: Agent Basics

**Objective:** Manage simple state with Agent.

**Task:** Implement a counter using Agent:

```elixir
defmodule Counter do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def increment do
    Agent.update(__MODULE__, fn count -> count + 1 end)
  end

  def decrement do
    Agent.update(__MODULE__, fn count -> count - 1 end)
  end

  def get do
    Agent.get(__MODULE__, fn count -> count end)
  end

  def reset(value \\ 0) do
    Agent.update(__MODULE__, fn _count -> value end)
  end
end
```

**Exercises:**
1. Start the counter with initial value 0
2. Increment 5 times from different processes
3. Read the value - is it correct?
4. When to use cast vs update?
5. Implement `get_and_increment/0`

**Test Concurrency:**
```elixir
Counter.start_link(0)

# Spawn 100 processes that each increment
for _ <- 1..100 do
  spawn(fn -> Counter.increment() end)
end

Process.sleep(100)
Counter.get()  # => 100
```

---

### Drill 5: Agent vs GenServer

**Objective:** Understand when to use Agent vs GenServer.

**Task:** Convert between implementations:

**Agent Version:**
```elixir
defmodule StackAgent do
  use Agent

  def start_link(initial \\ []) do
    Agent.start_link(fn -> initial end, name: __MODULE__)
  end

  def push(item) do
    Agent.update(__MODULE__, fn stack -> [item | stack] end)
  end

  def pop do
    Agent.get_and_update(__MODULE__, fn
      [] -> {{:error, :empty}, []}
      [head | tail] -> {{:ok, head}, tail}
    end)
  end
end
```

**GenServer Version:**
```elixir
defmodule StackServer do
  use GenServer

  def start_link(initial \\ []) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def push(item) do
    GenServer.cast(__MODULE__, {:push, item})
  end

  def pop do
    GenServer.call(__MODULE__, :pop)
  end

  @impl GenServer
  def init(initial), do: {:ok, initial}

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
end
```

**Comparison Questions:**
1. Which has less boilerplate?
2. When must you use GenServer?
3. Can Agent handle plain messages?
4. Can Agent run cleanup on termination?
5. Performance differences?

**When to Use Each:**
- **Agent**: Simple state, no plain messages, no termination logic
- **GenServer**: Handle messages, timeouts, termination, more complex scenarios

---

### Drill 6: ETS Tables Basics

**Objective:** Create and manipulate ETS tables.

**Task:** Explore ETS operations:

```elixir
defmodule ETSDrill do
  def demonstrate do
    # Create table
    table = :ets.new(:my_table, [:set, :public])

    # Insert data
    :ets.insert(table, {:alice, 30, "engineer"})
    :ets.insert(table, {:bob, 25, "designer"})
    :ets.insert(table, {:charlie, 35, "manager"})

    # Lookup
    IO.inspect(:ets.lookup(table, :alice))

    # Update (overwrites)
    :ets.insert(table, {:alice, 31, "senior engineer"})

    # Delete
    :ets.delete(table, :bob)

    # Convert to list
    IO.inspect(:ets.tab2list(table))

    # Match patterns
    engineers = :ets.match_object(table, {:_, :_, "engineer"})
    IO.inspect(engineers)

    # Cleanup
    :ets.delete(table)
  end
end
```

**Exercises:**
1. Create a `:bag` table - what's different?
2. Create a `:named_table` - how to access it?
3. Try `:ordered_set` - what's the difference?
4. Use `:protected` vs `:public` access
5. What happens when owner process dies?

**Table Types:**
- `:set` - One row per key (default)
- `:ordered_set` - Sorted by key
- `:bag` - Multiple rows per key (no duplicates)
- `:duplicate_bag` - Multiple rows, allows duplicates

**Access Modes:**
- `:protected` - Owner writes, all read (default)
- `:public` - All read/write
- `:private` - Owner only

---

### Drill 7: ETS Performance

**Objective:** Understand ETS performance characteristics.

**Task:** Compare GenServer vs ETS for key-value storage:

```elixir
defmodule KVBenchmark do
  def benchmark_genserver(operations) do
    GenServerKV.start_link()

    {time, _} = :timer.tc(fn ->
      for i <- 1..operations do
        GenServerKV.put(i, i * 2)
        GenServerKV.get(i)
      end
    end)

    IO.puts("GenServer: #{operations / (time / 1_000_000)} ops/sec")
  end

  def benchmark_ets(operations) do
    table = :ets.new(:bench, [:set, :public, write_concurrency: true])

    {time, _} = :timer.tc(fn ->
      for i <- 1..operations do
        :ets.insert(table, {i, i * 2})
        :ets.lookup(table, i)
      end
    end)

    IO.puts("ETS: #{operations / (time / 1_000_000)} ops/sec")
    :ets.delete(table)
  end

  def concurrent_benchmark(operations, concurrency) do
    table = :ets.new(:bench, [:set, :public, write_concurrency: true])

    {time, _} = :timer.tc(fn ->
      tasks = for _ <- 1..concurrency do
        Task.async(fn ->
          for i <- 1..operations do
            :ets.insert(table, {i, i * 2})
            :ets.lookup(table, i)
          end
        end)
      end

      Enum.each(tasks, &Task.await(&1, :infinity))
    end)

    total_ops = operations * concurrency
    IO.puts("ETS (#{concurrency} concurrent): #{total_ops / (time / 1_000_000)} ops/sec")
    :ets.delete(table)
  end
end
```

**Run Tests:**
```elixir
KVBenchmark.benchmark_genserver(10_000)
# => GenServer: ~1,000,000 ops/sec

KVBenchmark.benchmark_ets(10_000)
# => ETS: ~5,000,000 ops/sec

KVBenchmark.concurrent_benchmark(10_000, 4)
# => ETS (4 concurrent): ~15,000,000 ops/sec
```

**Insights:**
- ETS is 5-10x faster for simple operations
- ETS scales with concurrency (GenServer doesn't)
- Data is copied to/from ETS
- No garbage collection pressure in ETS

---

## Integration Exercises

### Exercise 1: Parallel Data Processing Pipeline

**Objective:** Use Tasks for parallel data processing.

**Concepts Reinforced:**
- Tasks (Chapter 10)
- Streams (Chapter 3)
- Enum operations (Chapter 3)
- Error handling (Chapter 8)

**Task:** Build a parallel data processing pipeline:

```elixir
defmodule DataPipeline do
  def process_file(file_path) do
    file_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.chunk_every(100)
    |> process_chunks_parallel()
    |> Enum.to_list()
  end

  defp process_chunks_parallel(chunks) do
    chunks
    |> Task.async_stream(
      &process_chunk/1,
      max_concurrency: System.schedulers_online(),
      timeout: 30_000
    )
    |> Stream.map(fn
      {:ok, result} -> result
      {:exit, reason} -> {:error, reason}
    end)
  end

  defp process_chunk(lines) do
    lines
    |> Enum.map(&parse_line/1)
    |> Enum.filter(&valid?/1)
    |> Enum.map(&transform/1)
    |> aggregate()
  end

  defp parse_line(line) do
    # Parse CSV or JSON
    [timestamp, value] = String.split(line, ",")
    %{timestamp: String.to_integer(timestamp), value: String.to_float(value)}
  end

  defp valid?(%{value: value}), do: value > 0

  defp transform(%{timestamp: ts, value: v}) do
    %{
      timestamp: ts,
      value: v,
      normalized: v / 100.0,
      category: categorize(v)
    }
  end

  defp categorize(v) when v < 33, do: :low
  defp categorize(v) when v < 66, do: :medium
  defp categorize(_), do: :high

  defp aggregate(records) do
    %{
      count: length(records),
      sum: Enum.sum(Enum.map(records, & &1.value)),
      categories: Enum.frequencies_by(records, & &1.category)
    }
  end
end
```

**Requirements:**
1. Process file in parallel chunks
2. Handle errors gracefully (use Task.async_stream)
3. Utilize all CPU cores
4. Aggregate results from all chunks
5. Handle timeout scenarios

**Test:**
```elixir
# Create test data
File.write!("data.csv", Enum.map(1..10_000, fn i ->
  "#{i},#{:rand.uniform() * 100}\n"
end) |> Enum.join())

# Process
results = DataPipeline.process_file("data.csv")
IO.inspect(results)
```

**Success Criteria:**
- All chunks processed in parallel
- Proper error handling
- Faster than sequential processing
- Correct aggregated results

---

### Exercise 2: Cached API Client with ETS

**Objective:** Build a caching layer with ETS.

**Concepts Reinforced:**
- ETS tables (Chapter 10)
- GenServer (Chapter 6)
- Supervision (Chapter 9)
- TTL and expiration (Chapter 9)

**Task:**

```elixir
defmodule CachedAPIClient do
  use GenServer

  defstruct [:cache_table, :ttl_seconds]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def fetch(url) do
    case get_cached(url) do
      {:ok, data} ->
        {:ok, data, :from_cache}

      :miss ->
        fetch_and_cache(url)
    end
  end

  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  def cache_stats do
    GenServer.call(__MODULE__, :stats)
  end

  ## Private API

  defp get_cached(url) do
    case :ets.lookup(__MODULE__, url) do
      [{^url, data, cached_at}] ->
        if fresh?(cached_at) do
          {:ok, data}
        else
          :miss
        end

      [] ->
        :miss
    end
  end

  defp fresh?(cached_at) do
    now = System.system_time(:second)
    GenServer.call(__MODULE__, :get_ttl) >= (now - cached_at)
  end

  defp fetch_and_cache(url) do
    GenServer.call(__MODULE__, {:fetch_and_cache, url}, 30_000)
  end

  ## Callbacks

  @impl GenServer
  def init(opts) do
    ttl = Keyword.get(opts, :ttl_seconds, 300)

    table = :ets.new(__MODULE__, [
      :named_table,
      :public,
      :set,
      read_concurrency: true
    ])

    schedule_cleanup()

    {:ok, %__MODULE__{cache_table: table, ttl_seconds: ttl}}
  end

  @impl GenServer
  def handle_call(:get_ttl, _from, state) do
    {:reply, state.ttl_seconds, state}
  end

  def handle_call({:fetch_and_cache, url}, _from, state) do
    # Check again in case another process cached it
    case get_cached(url) do
      {:ok, data} ->
        {:reply, {:ok, data, :from_cache}, state}

      :miss ->
        case perform_fetch(url) do
          {:ok, data} ->
            now = System.system_time(:second)
            :ets.insert(state.cache_table, {url, data, now})
            {:reply, {:ok, data, :fetched}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call(:clear_cache, _from, state) do
    :ets.delete_all_objects(state.cache_table)
    {:reply, :ok, state}
  end

  def handle_call(:stats, _from, state) do
    info = :ets.info(state.cache_table)
    stats = %{
      size: info[:size],
      memory: info[:memory],
      ttl: state.ttl_seconds
    }
    {:reply, stats, state}
  end

  @impl GenServer
  def handle_info(:cleanup, state) do
    now = System.system_time(:second)
    cutoff = now - state.ttl_seconds

    :ets.select_delete(state.cache_table, [
      {{:_, :_, :"$1"}, [{:<, :"$1", cutoff}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp perform_fetch(url) do
    # Simulate HTTP request
    Process.sleep(100)
    {:ok, "Data from #{url}"}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, 60_000)
  end
end
```

**Requirements:**
1. Cache API responses in ETS
2. TTL-based expiration
3. Periodic cleanup of stale entries
4. Concurrent reads without blocking
5. Statistics tracking

**Test:**
```elixir
CachedAPIClient.start_link(ttl_seconds: 10)

# First fetch - hits API
{:ok, data, :fetched} = CachedAPIClient.fetch("https://api.example.com/users")

# Second fetch - from cache
{:ok, data, :from_cache} = CachedAPIClient.fetch("https://api.example.com/users")

# Stats
CachedAPIClient.cache_stats()
# => %{size: 1, memory: 338, ttl: 10}

# Wait for expiration
Process.sleep(11_000)

# Fetches again
{:ok, data, :fetched} = CachedAPIClient.fetch("https://api.example.com/users")
```

---

### Exercise 3: State Machine with Agent

**Objective:** Build a simple state machine using Agent.

**Concepts Reinforced:**
- Agent (Chapter 10)
- Pattern matching (Chapter 3)
- GenServer timeout patterns (Chapter 9)

**Task:** Implement a traffic light controller:

```elixir
defmodule TrafficLight do
  use Agent

  @transitions %{
    :red => :green,
    :green => :yellow,
    :yellow => :red
  }

  @durations %{
    :red => 5_000,
    :green => 5_000,
    :yellow => 2_000
  }

  defstruct [:current_state, :changed_at, :timer_ref]

  def start_link(initial_state \\ :red) do
    Agent.start_link(
      fn ->
        {:ok, timer_ref} = schedule_transition(initial_state)
        %__MODULE__{
          current_state: initial_state,
          changed_at: System.monotonic_time(:millisecond),
          timer_ref: timer_ref
        }
      end,
      name: __MODULE__
    )
  end

  def current_state do
    Agent.get(__MODULE__, fn state -> state.current_state end)
  end

  def time_in_state do
    Agent.get(__MODULE__, fn state ->
      now = System.monotonic_time(:millisecond)
      now - state.changed_at
    end)
  end

  def force_transition do
    Agent.get_and_update(__MODULE__, fn state ->
      # Cancel old timer
      if state.timer_ref, do: Process.cancel_timer(state.timer_ref)

      # Transition
      new_state = do_transition(state)

      {:ok, new_state}
    end)
  end

  def handle_timeout do
    Agent.update(__MODULE__, &do_transition/1)
  end

  defp do_transition(state) do
    next = Map.get(@transitions, state.current_state)
    {:ok, timer_ref} = schedule_transition(next)

    %__MODULE__{
      current_state: next,
      changed_at: System.monotonic_time(:millisecond),
      timer_ref: timer_ref
    }
  end

  defp schedule_transition(state) do
    duration = Map.get(@durations, state)
    timer_ref = Process.send_after(self(), :timeout, duration)
    {:ok, timer_ref}
  end
end
```

**Additional Component:**
```elixir
defmodule TrafficLightServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, _} = TrafficLight.start_link()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    TrafficLight.handle_timeout()
    {:noreply, state}
  end
end
```

**Success Criteria:**
- State transitions automatically
- Correct timing for each state
- Can query current state
- Can force early transition
- Clean timer management

---

### Exercise 4: Leaderboard with ETS

**Objective:** Build a high-performance leaderboard.

**Concepts Reinforced:**
- ETS tables (Chapter 10)
- Ordered sets (Chapter 10)
- Concurrent operations (Chapter 5)
- GenServer (Chapter 6)

**Task:**

```elixir
defmodule Leaderboard do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def update_score(player_id, score) do
    :ets.insert(:leaderboard, {score, player_id, System.system_time()})
    :ok
  end

  def get_rank(player_id) do
    GenServer.call(__MODULE__, {:get_rank, player_id})
  end

  def top_n(n \\ 10) do
    :leaderboard
    |> :ets.tab2list()
    |> Enum.sort_by(fn {score, _player, _time} -> -score end)
    |> Enum.take(n)
    |> Enum.map(fn {score, player, _time} -> {player, score} end)
  end

  def players_above(score) do
    :ets.select(:leaderboard, [
      {{:"$1", :"$2", :_}, [{:>, :"$1", score}], [{{:"$2", :"$1"}}]}
    ])
  end

  def player_count do
    :ets.info(:leaderboard, :size)
  end

  ## Callbacks

  @impl GenServer
  def init(_) do
    :ets.new(:leaderboard, [
      :named_table,
      :public,
      :duplicate_bag,
      write_concurrency: true,
      read_concurrency: true
    ])

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:get_rank, player_id}, _from, state) do
    # Find player's best score
    player_scores = :ets.match(:leaderboard, {:"$1", player_id, :_})

    case player_scores do
      [] ->
        {:reply, :not_found, state}

      scores ->
        best_score = Enum.max(List.flatten(scores))

        # Count players with higher scores
        better_count = :ets.select_count(:leaderboard, [
          {{:"$1", :_, :_}, [{:>, :"$1", best_score}], [true]}
        ])

        rank = better_count + 1
        {:reply, {:ok, rank, best_score}, state}
    end
  end
end
```

**Requirements:**
1. Store player scores in ETS
2. Support concurrent updates
3. Fast rank lookup
4. Top N query
5. Range queries

**Test:**
```elixir
Leaderboard.start_link(nil)

# Update scores concurrently
tasks = for i <- 1..1000 do
  Task.async(fn ->
    Leaderboard.update_score("player_#{i}", :rand.uniform(10000))
  end)
end

Enum.each(tasks, &Task.await/1)

# Query
Leaderboard.top_n(10)
Leaderboard.get_rank("player_500")
Leaderboard.players_above(9000)
Leaderboard.player_count()
```

---

## Capstone Project: Distributed Job Queue with Metrics

### Project Description

Build a comprehensive job queue system that uses Tasks for job execution, ETS for high-performance queue storage, Agents for metrics aggregation, and full supervision for fault tolerance. The system should handle thousands of concurrent jobs, track detailed metrics, and provide real-time monitoring.

### Architecture

```
JobQueue.System (Supervisor)
├── JobQueue.Registry (Process registry)
├── JobQueue.Storage (GenServer + ETS owner)
├── JobQueue.TaskSupervisor (Dynamic task supervision)
├── JobQueue.Metrics (Agent for stats)
└── JobQueue.Monitor (Periodic reporter)
```

### Requirements

#### 1. ETS-Based Queue Storage

```elixir
defmodule JobQueue.Storage do
  use GenServer

  @table :job_queue

  ## API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def enqueue(job_id, job_data, priority \\ 5) do
    timestamp = System.system_time(:millisecond)
    # Negative priority for sorting (higher priority = lower number)
    :ets.insert(@table, {-priority, timestamp, job_id, job_data})
    :ok
  end

  def dequeue do
    case :ets.first(@table) do
      :"$end_of_table" ->
        :empty

      key ->
        case :ets.lookup(@table, key) do
          [{_prio, _ts, job_id, job_data}] ->
            :ets.delete(@table, key)
            {:ok, job_id, job_data}

          [] ->
            :empty
        end
    end
  end

  def size do
    :ets.info(@table, :size)
  end

  def list_jobs(limit \\ 100) do
    @table
    |> :ets.tab2list()
    |> Enum.sort()
    |> Enum.take(limit)
  end

  def delete_job(job_id) do
    :ets.match_delete(@table, {:_, :_, job_id, :_})
  end

  ## Callbacks

  @impl GenServer
  def init(_) do
    :ets.new(@table, [
      :ordered_set,
      :named_table,
      :public,
      write_concurrency: true
    ])

    {:ok, %{}}
  end
end
```

#### 2. Metrics with Agent

```elixir
defmodule JobQueue.Metrics do
  use Agent

  defstruct [
    jobs_enqueued: 0,
    jobs_started: 0,
    jobs_completed: 0,
    jobs_failed: 0,
    total_processing_time_ms: 0,
    errors: []
  ]

  def start_link(_) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  def increment(metric) do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, metric, &(&1 + 1))
    end)
  end

  def add_processing_time(milliseconds) do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, :total_processing_time_ms, &(&1 + milliseconds))
    end)
  end

  def record_error(job_id, reason) do
    Agent.update(__MODULE__, fn state ->
      error = %{
        job_id: job_id,
        reason: reason,
        timestamp: System.system_time(:second)
      }

      errors = [error | Enum.take(state.errors, 99)]
      %{state | errors: errors}
    end)
  end

  def get_stats do
    Agent.get(__MODULE__, fn state ->
      completed = state.jobs_completed

      avg_time = if completed > 0 do
        state.total_processing_time_ms / completed
      else
        0
      end

      %{
        enqueued: state.jobs_enqueued,
        started: state.jobs_started,
        completed: completed,
        failed: state.jobs_failed,
        in_progress: state.jobs_started - completed - state.jobs_failed,
        avg_processing_time_ms: avg_time,
        recent_errors: Enum.take(state.errors, 10)
      }
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> %__MODULE__{} end)
  end
end
```

#### 3. Job Processor with Tasks

```elixir
defmodule JobQueue.Processor do
  def start_link(_) do
    Task.Supervisor.start_link(name: __MODULE__)
  end

  def process_next do
    case JobQueue.Storage.dequeue() do
      {:ok, job_id, job_data} ->
        start_job(job_id, job_data)

      :empty ->
        :no_jobs
    end
  end

  defp start_job(job_id, job_data) do
    Task.Supervisor.start_child(__MODULE__, fn ->
      execute_job(job_id, job_data)
    end)
  end

  defp execute_job(job_id, job_data) do
    JobQueue.Metrics.increment(:jobs_started)
    start_time = System.monotonic_time(:millisecond)

    try do
      result = perform_job(job_data)

      duration = System.monotonic_time(:millisecond) - start_time
      JobQueue.Metrics.add_processing_time(duration)
      JobQueue.Metrics.increment(:jobs_completed)

      {:ok, result}
    rescue
      e ->
        JobQueue.Metrics.increment(:jobs_failed)
        JobQueue.Metrics.record_error(job_id, Exception.message(e))
        {:error, e}
    end
  end

  defp perform_job(%{type: :compute, data: data}) do
    # Simulate CPU work
    Process.sleep(100)
    {:ok, data * 2}
  end

  defp perform_job(%{type: :io, path: path}) do
    # Simulate IO
    Process.sleep(200)
    {:ok, "processed #{path}"}
  end

  defp perform_job(%{type: :network, url: url}) do
    # Simulate network call
    Process.sleep(300)
    {:ok, "fetched #{url}"}
  end

  defp perform_job(%{type: :error}) do
    # Intentional error for testing
    raise "Intentional job failure"
  end
end
```

#### 4. Worker Pool

```elixir
defmodule JobQueue.Worker do
  use Task, restart: :transient

  def start_link(_arg) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run do
    loop()
  end

  defp loop do
    case JobQueue.Processor.process_next() do
      {:ok, _pid} ->
        # Job started, fetch next
        loop()

      :no_jobs ->
        # Wait a bit before checking again
        Process.sleep(100)
        loop()
    end
  end
end
```

#### 5. Metrics Monitor

```elixir
defmodule JobQueue.Monitor do
  use Task

  def start_link(_arg) do
    Task.start_link(fn -> loop() end)
  end

  defp loop do
    Process.sleep(5_000)

    stats = JobQueue.Metrics.get_stats()
    queue_size = JobQueue.Storage.size()

    report = %{
      timestamp: DateTime.utc_now(),
      queue_size: queue_size,
      stats: stats
    }

    IO.inspect(report, label: "Job Queue Status", pretty: true)

    loop()
  end
end
```

#### 6. Main API

```elixir
defmodule JobQueue do
  def submit(job_data, priority \\ 5) do
    job_id = generate_id()
    JobQueue.Storage.enqueue(job_id, job_data, priority)
    JobQueue.Metrics.increment(:jobs_enqueued)
    {:ok, job_id}
  end

  def stats do
    JobQueue.Metrics.get_stats()
  end

  def queue_size do
    JobQueue.Storage.size()
  end

  def list_jobs(limit \\ 10) do
    JobQueue.Storage.list_jobs(limit)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64()
  end
end
```

#### 7. System Supervisor

```elixir
defmodule JobQueue.System do
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl Supervisor
  def init(:ok) do
    children = [
      JobQueue.Storage,
      JobQueue.Metrics,
      JobQueue.Processor,
      JobQueue.Monitor,
      {Task.Supervisor, name: JobQueue.WorkerPool},
      # Start worker pool
      %{
        id: JobQueue.Workers,
        start: {Task.Supervisor, :start_link, [[name: JobQueue.Workers]]},
        type: :supervisor
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### Additional Features

#### 1. Job Retry Logic

```elixir
defmodule JobQueue.Retry do
  @max_retries 3

  def should_retry?(job_id) do
    retry_count = get_retry_count(job_id)
    retry_count < @max_retries
  end

  def retry_job(job_id, job_data) do
    increment_retry_count(job_id)
    delay = backoff_delay(get_retry_count(job_id))

    Process.send_after(self(), {:retry, job_id, job_data}, delay)
  end

  defp backoff_delay(attempt) do
    # Exponential backoff: 1s, 2s, 4s
    trunc(:math.pow(2, attempt)) * 1000
  end

  defp get_retry_count(job_id) do
    case :ets.lookup(:job_retries, job_id) do
      [{^job_id, count}] -> count
      [] -> 0
    end
  end

  defp increment_retry_count(job_id) do
    :ets.update_counter(:job_retries, job_id, {2, 1}, {job_id, 0})
  end
end
```

#### 2. Job Priority Levels

```elixir
defmodule JobQueue.Priority do
  @critical 1
  @high 3
  @normal 5
  @low 7
  @background 9

  def critical, do: @critical
  def high, do: @high
  def normal, do: @normal
  def low, do: @low
  def background, do: @background
end
```

#### 3. Rate Limiting

```elixir
defmodule JobQueue.RateLimiter do
  use Agent

  def start_link(max_per_second) do
    Agent.start_link(
      fn -> %{max: max_per_second, current: 0, window_start: System.monotonic_time(:second)} end,
      name: __MODULE__
    )
  end

  def allow? do
    Agent.get_and_update(__MODULE__, fn state ->
      now = System.monotonic_time(:second)

      state = if now > state.window_start do
        %{state | current: 0, window_start: now}
      else
        state
      end

      if state.current < state.max do
        {true, %{state | current: state.current + 1}}
      else
        {false, state}
      end
    end)
  end
end
```

### Bonus Challenges

1. **Scheduled Jobs**
   - Support jobs scheduled for future execution
   - Use ETS ordered_set with timestamp-based keys

2. **Job Dependencies**
   - Jobs can depend on other jobs
   - DAG-based execution

3. **Dead Letter Queue**
   - Failed jobs go to DLQ after max retries
   - Manual inspection and retry

4. **Job Cancellation**
   - Cancel jobs by ID
   - Stop running jobs gracefully

5. **Distributed Queue**
   - Run across multiple nodes
   - Distribute work via Registry

6. **Persistence**
   - Save queue to disk
   - Reload on restart

### Evaluation Criteria

**ETS Usage (25 points)**
- Correct table type selection (5 pts)
- Efficient operations (10 pts)
- Concurrent access handling (5 pts)
- Memory management (5 pts)

**Task Management (25 points)**
- Proper Task.Supervisor usage (10 pts)
- Error handling (5 pts)
- Concurrent execution (5 pts)
- Resource cleanup (5 pts)

**Agent Implementation (15 points)**
- Metrics tracking (10 pts)
- Concurrent safety (5 pts)

**Features (20 points)**
- Priority queue (5 pts)
- Metrics/monitoring (5 pts)
- Job processing (5 pts)
- Error handling (5 pts)

**Code Quality (15 points)**
- Clean architecture (5 pts)
- Documentation (5 pts)
- Testing (5 pts)

### Testing Scenarios

```elixir
# Start system
JobQueue.System.start_link(nil)

# Submit jobs
for i <- 1..1000 do
  priority = Enum.random([1, 3, 5, 7, 9])
  type = Enum.random([:compute, :io, :network])

  JobQueue.submit(%{type: type, data: i}, priority)
end

# Monitor progress
Stream.interval(1000)
|> Stream.take(20)
|> Enum.each(fn _ ->
  IO.inspect(JobQueue.stats())
end)

# Stress test
tasks = for _ <- 1..10 do
  Task.async(fn ->
    for i <- 1..1000 do
      JobQueue.submit(%{type: :compute, data: i})
    end
  end)
end

Enum.each(tasks, &Task.await(&1, :infinity))

# Final stats
JobQueue.stats()
JobQueue.queue_size()
```

---

## Success Checklist

Before moving to Chapter 11, ensure you can:

- [ ] Use Task.async/await for parallel computations
- [ ] Start non-awaited tasks with Task.start_link
- [ ] Supervise tasks with Task.Supervisor
- [ ] Understand Task.async_stream for collections
- [ ] Know when to use Agent vs GenServer
- [ ] Implement simple state management with Agent
- [ ] Understand Agent is built on GenServer
- [ ] Create and configure ETS tables
- [ ] Choose appropriate table types (:set, :ordered_set, :bag, :duplicate_bag)
- [ ] Set access permissions correctly
- [ ] Perform basic ETS operations (insert, lookup, delete)
- [ ] Use match patterns for queries
- [ ] Understand ETS performance characteristics
- [ ] Know when ETS is better than GenServer
- [ ] Manage ETS table ownership
- [ ] Use :write_concurrency and :read_concurrency options
- [ ] Implement cleanup for ETS tables

---

## Looking Ahead

Chapter 11 explores working with OTP applications and components:
- **Applications** - Packaging and dependency management
- **Application behavior** - Start/stop lifecycle
- **Releases** - Deploying complete systems
- **Configuration** - Managing application config

These concepts enable building production-ready, deployable Elixir systems!
