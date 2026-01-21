This looks like a solid plan. **Chapter 7** is indeed a pivotal moment where we transition from isolated scripts to a structured **System**. This is where the power of the BEAM really starts to shine.

---

# Chapter 7: Building a Concurrent System

## 1. Chapter Summary

**The Mix Tool**

* **Project Structure:** We move away from single files. `mix new todo` creates a standard directory structure:
* `lib/`: Source code. (e.g., `lib/todo/server.ex` defines `Todo.Server`).
* `test/`: Unit tests.
* `mix.exs`: Project configuration and dependencies.


* **Workflow:**
* `mix compile`: Compiles the project.
* `iex -S mix`: Starts a shell with your project loaded (the standard way to develop).
* `mix test`: Runs the test suite defined in `test/`.



**Managing Multiple Processes (The Cache)**

* A single `Todo.Server` process can only manage *one* list. To manage *many* lists (Alice's, Bob's, etc.), we need a discovery mechanism.
* **The Cache Process:** This acts as a registry. It maps a "List Name" to a "Server PID".
* **Dynamic Spawning:** When a client asks for "Bob's List", the Cache checks its state map.
* *If exists:* Returns the PID.
* *If missing:* Spawns a new `Todo.Server`, stores the PID, and returns it.


* **Bottleneck Analysis:** The Cache is a single process, so requests to *find* a list are serialized. However, once a client has the PID of a specific `Todo.Server`, interactions with that server bypass the Cache entirely, allowing massive concurrency.
**Persisting Data (The Database)**
* We introduce persistence so data survives restarts.
* **The Bottleneck:** File I/O is slow. A single Database process doing file writes would block the entire system.
* **Pooling:** We create a **Pool** of database workers (e.g., 3 processes).
* **Routing & Consistency:** To avoid race conditions (two workers writing to the same file at once), we use **Hashing** (`:erlang.phash2`). Requests for "Bob's List" are *always* routed to Worker 1. Requests for "Alice's List" might always go to Worker 2.

**Reasoning with Processes**

* **Processes as Services:** Think of each process as a microservice. `Todo.Cache` is a naming service; `Todo.Database` is a storage service.
* **Call vs. Cast:**
* **Call (Synchronous):** Use when you need a return value or **Backpressure** (preventing the client from overwhelming the server).
* **Cast (Asynchronous):** Use for "fire and forget" speed, but be careful of overloading the receiver's mailbox.



---

## 2. Drills

*These drills ensure you understand the mechanics of Mix and process coordination.*

### Drill 1: Mix Commands

**Task:** Match the command to the action.

1. `mix test`
2. `mix new my_app`
3. `iex -S mix`

A. Creates a standard project skeleton.
B. Starts the interactive shell with your code loaded.
C. Executes the files in the `test/` directory.

### Drill 2: The Router Pattern

**Task:** You have a pool of 3 workers stored in a map: `%{0 => pid_a, 1 => pid_b, 2 => pid_c}`.
Write a function `get_worker(pool, key)` that selects a worker PID based on the key using `:erlang.phash2`.

**Your Solution:**

```elixir
def get_worker(pool, key) do
  # calculate index 0-2
  index = :erlang.phash2(key, 3)
  # fetch from map
  Map.get(pool, index)
end

```

### Drill 3: Synchronization Logic

**Scenario:** You have a `BankAccount` process.
**Question:** Two clients try to withdraw money from the *same* account at the exact same time. Do you need a mutex lock or atomic database transaction to prevent a race condition?
**Answer:** No. Why? (Hint: Think about how a single process handles its mailbox).

---

## 3. The Project: The Concurrent Todo System

We will transform our simple Todo Server into a robust **Mix Project** with multiple actors.

### Step 1: Project Setup

1. Run `mix new todo` in your terminal.
2. Move your code from previous chapters into `lib/todo/`.
* `lib/todo/list.ex` (The functional Core)
* `lib/todo/server.ex` (The GenServer)



### Step 2: The Cache (Registry)

Create `lib/todo/cache.ex`.

* **Init:** State is an empty map.
* **Handle Call (`:server_process`):**
* Input: `list_name`.
* Logic: Check map. If exists, return PID. If not, start `Todo.Server`, store PID, return PID.



### Step 3: Database Workers

Create `lib/todo/database_worker.ex`.

* This process handles the actual file I/O.
* **Requests:**
* `store(key, data)`: Writes binary data to disk.
* `get(key)`: Reads binary data from disk.



### Step 4: The Database Pool (The Router)

Create `lib/todo/database.ex`.

* **Init:** Starts 3 instances of `DatabaseWorker`. Stores them in a map/tuple.
* **Store/Get:** Hashes the key to pick *one* worker, then forwards the request to that worker.

### Step 5: Integration

Modify `Todo.Server`:

* **Init:** On startup, call `Todo.Database.get(name)` to load previous items.
* **Add/Delete:** On every change, call `Todo.Database.store(name, new_list)` to save.

### Step 6: Verification (The "Smoke Test")

Run `iex -S mix`.

```elixir
# 1. Start the system
{:ok, cache} = Todo.Cache.start()

# 2. Create a list for Bob
pid = Todo.Cache.server_process(cache, "bob")
Todo.Server.add_entry(pid, %{date: ~D[2023-01-01], title: "Save me!"})

# 3. CRASH IT (Simulate a restart)
# Exit iex (Ctrl+C twice) and restart `iex -S mix`

# 4. Verify Persistence
{:ok, cache} = Todo.Cache.start()
pid = Todo.Cache.server_process(cache, "bob")
Todo.Server.entries(pid, ~D[2023-01-01])
# Should return "Save me!"

```

---

### Self-Correction Checklist

* [ ] Did you update `mix.exs` or the file structure correctly?
* [ ] Does `Todo.Server` now take a `name` argument in `start_link` so it knows where to save data?
* [ ] Are you routing database requests consistently? (e.g., "bob" always goes to Worker 1).

---

### Ready for the next step?

Your system is now functional, concurrent, and persistent. But it has a flaw: **If a process crashes, it stays dead.** We have no automatic recovery.

In **Chapter 8**, we will learn about **Fault Tolerance**. We will introduce **Supervisors**, the mechanism that makes Erlang/Elixir systems "self-healing."