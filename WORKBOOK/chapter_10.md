We are now moving beyond the "one-size-fits-all" `GenServer`. While `GenServer` can do anything, it isn't always the best tool for the job. This chapter introduces specialized tools for specific patterns: **Tasks** (jobs), **Agents** (state), and **ETS** (high-performance shared data).

---

# Chapter 10: Beyond GenServer – Tasks, Agents, and ETS

## 1. Chapter Summary

**Tasks (`Task`)**

* **Purpose:** One-off concurrent jobs. Unlike a server, a Task computes something and then dies.
* **Awaited Tasks (`Task.async/1` + `Task.await/2`):** Spawns a process to run a function. The caller can wait for the result. Useful for parallelizing independent operations (e.g., running 5 database queries at once).
* **Non-Awaited Tasks (`Task.start_link/1`):** Fire-and-forget background jobs. Useful for side effects where you don't need a return value.

**Agents (`Agent`)**

* **Purpose:** Simple state management.
* **Abstraction:** An `Agent` is a wrapper around `GenServer` designed specifically for holding state. It removes the boilerplate of `handle_call` and `handle_cast`.
* **Usage:**
* `Agent.get(pid, lambda)`: synchronous read.
* `Agent.update(pid, lambda)`: synchronous update.
* `Agent.cast(pid, lambda)`: asynchronous update.


* **Trade-off:** Agents are simpler but less flexible. If you need complex message handling (like `handle_info` or `terminate`), you must go back to `GenServer`.

**ETS (Erlang Term Storage)**

* **The Problem:** A single `GenServer` process is a bottleneck. It handles requests serially (one by one). If 10,000 clients try to read from one cache process, they form a queue.
* **The Solution:** ETS Tables. These are in-memory storage tables provided by the BEAM runtime (written in C).
* **Shared State:** Unlike processes, ETS tables allow **concurrent reads and writes** from multiple processes.
* **Semantics:**
* Tables are owned by a process (if the owner dies, the table is deleted).
* Data is **deep copied** in and out of the table (except for binaries).
* Operations are atomic (insert, lookup, delete).



---

## 2. Drills

*These drills practice the specific syntax of these new tools.*

### Drill 1: Parallel Map with Tasks

**Task:** Use `Task.async` and `Task.await` to parallelize a slow operation.
Given the list `[1, 2, 3]`, simulate a slow calculation (sleep 1s, then square the number) for each item *concurrently*. The total time should be ~1 second, not 3.

**Your Solution:**

```elixir
[1, 2, 3]
|> Enum.map(fn x ->
  Task.async(fn ->
    # ... sleep and return x * x
  end)
end)
|> Enum.map(&Task.await/1)

```

### Drill 2: The Agent Counter

**Task:** Create a counter using `Agent`.

1. Start an Agent with an initial state of `0`.
2. Increment it by 1 (using `Agent.update`).
3. Read the value (using `Agent.get`).

**Your Solution:**

```elixir
{:ok, pid} = Agent.start_link(fn -> 0 end)
# ... write update and get

```

### Drill 3: ETS Basics

**Task:**

1. Create a **named**, **public** ETS table called `:my_cache`.
2. Insert a tuple `{:user_1, "Alice"}`.
3. Look it up.

**Your Solution:**

```elixir
:ets.new(:my_cache, [:named_table, :public])
# ... write insert and lookup

```

---

## 3. The Project: Optimization & Refactoring

We will optimize our Todo System using these new tools.

### Part 1: The Metrics Reporter (Task)

We want to monitor our system health.
**Goal:** Create a `Todo.Metrics` module that logs memory usage every 10 seconds.

1. Create `lib/todo/metrics.ex`.
2. Use `use Task` (to get `child_spec`).
3. Implement `start_link(_)` to call `Task.start_link/1`.
4. Pass a loop function that:
* Sleeps for 10 seconds.
* Prints process count (`:erlang.system_info(:process_count)`) and memory (`:erlang.memory(:total)`).
* Recurses.


5. Add `Todo.Metrics` to your `Todo.System` supervision tree.

### Part 2: Refactoring Todo.Server (Agent)

Our `Todo.Server` logic is actually quite simple: it just holds a struct and updates it. It doesn't handle complex messages.
**Goal:** Replace the `GenServer` code in `Todo.Server` with `Agent`.

* **Start:** `Agent.start_link` (load data from DB in the anonymous function).
* **Add Entry:** `Agent.cast`.
* **Entries:** `Agent.get`.
* **Expiry:** *Wait!* The book notes that `Agent` cannot easily handle timeouts/expiry (`handle_info`).
* **Decision:** If you implemented the expiry logic from Chapter 9, stick with `GenServer`. If not, try refactoring to `Agent` to see how much code it deletes.



### Part 3: The Custom Process Registry (ETS) [Major Challenge]

The built-in `Registry` is great, but building one yourself using ETS is the ultimate test of understanding concurrency bottlenecks.

**Goal:** Create `SimpleRegistry` using a `GenServer` + `ETS`.

* **The GenServer:**
* In `init`, create a named, public ETS table.
* Trap exits (`Process.flag(:trap_exit, true)`).
* Handle `{:EXIT, pid, _reason}` messages to delete entries from the ETS table when a process dies.


* **The Interface (Client-side):**
* `register(name)`:
1. Get `self()` (the PID).
2. **Write directly to ETS**: `:ets.insert_new(table, {name, pid})`.
3. If successful, send a message to the GenServer so it can link to `self()` (to track when you die).


* `whereis(name)`:
1. **Read directly from ETS**: `:ets.lookup(table, name)`.
2. Do **not** call the GenServer (this avoids the bottleneck).





**Why this matters:** This architecture separates **Reads** (which go to fast, concurrent ETS) from **Writes/Management** (which go to the serialized GenServer). This is a common high-performance pattern in Elixir.

---

### Self-Correction Checklist

* [ ] **Tasks:** Did you start the Metrics task under the Supervisor? If it crashes, does it restart?
* [ ] **ETS:** Did you make the table `:public`? If it's `:protected` (default), clients cannot write to it directly.
* [ ] **ETS:** In `SimpleRegistry`, are you performing lookups using `:ets.lookup` in the *client* process, not inside `GenServer.call`?

---

### Ready for the next step?

We have pushed a single node to its limits. We have concurrency, fault tolerance, and high-performance storage. Now it is time to go **Distributed**. In **Chapter 11**, we will prepare our application for production by building an **Application** and configuring it properly.
