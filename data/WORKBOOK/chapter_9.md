This chapter is about architecture. You are moving from "I have a Supervisor" to "I have a **Supervision Tree**." This is the secret sauce that allows Elixir systems to run for years without downtime: isolation.

---

# Chapter 9: Isolating Error Effects

## 1. Chapter Summary

**The Problem with a Flat Tree**
In Chapter 8, we had a single Supervisor restarting everything.

* **The Risk:** If *one* database worker crashes, the Supervisor might restart the *entire* Cache, which in turn kills *all* Todo Servers. A minor failure causes a major service interruption.
* **The Goal:** Isolate failures. A database crash should only restart the database subsystem. A single Todo List crash should only restart that specific list.

**The Solution: Nested Supervisors**
We build a hierarchy (a tree) of supervisors.

* **`Todo.System` (Root):** Supervises the high-level services (Cache, Database, Registry).
* **`Todo.Database` (Supervisor):** Supervises a pool of workers. If a worker crashes, only this pool is affected.
* **`Todo.Cache` (DynamicSupervisor):** Supervises the Todo Servers.

**Dynamic Supervision**

* **Standard Supervisor:** Starts a fixed list of children at boot time (e.g., the Database Pool).
* **DynamicSupervisor:** Starts with *no* children. Children are added on demand (e.g., when a user creates a new Todo List).
* Use `DynamicSupervisor.start_child/2` to spawn a new worker under this supervisor.



**Process Discovery (The Registry)**

* When a process is restarted by a Supervisor, its **PID changes**.
* We cannot store PIDs in a map (like we did in Chapter 7) because that map would become stale immediately after a crash.
* **The Solution:** Use `Registry` (a local, highly optimized process registry).
* Processes register themselves with a name (e.g., `{:todo_server, "Bob"}`) on startup.
* Clients look up the PID by name via the Registry.
* If a process crashes and restarts, it re-registers with the same name but a new PID. The client simply looks it up again.



**"Let It Crash" Philosophy**

* **Error Kernel:** The parts of your system that *must not* crash (usually the root supervisors and state-holders). Keep these simple.
* **Workers:** Should crash if they encounter invalid state.
* **State Recovery:** When a process crashes, its memory is wiped. To survive a crash, state must be persisted (to disk or DB) and re-loaded in `init`.

---

## 2. Drills

*These drills focus on the new architectural components.*

### Drill 1: Registry Lookup

**Task:** You have a registry named `MyRegistry`. You want to send a message to a process registered under the key `"worker_1"`. Write the code to find the PID and send the message.

**Your Solution:**

```elixir
case Registry.lookup(MyRegistry, "worker_1") do
  [{pid, _value}] ->
    # ... send message
  [] ->
    IO.puts("Process not found")
end

```

### Drill 2: Via Tuples

**Task:** Instead of manually looking up the PID, write a `GenServer.call` that uses a **Via Tuple** to route the request automatically through `MyRegistry` to `"worker_1"`.

**Your Solution:**

```elixir
via = {:via, Registry, {MyRegistry, "worker_1"}}
GenServer.call(via, :some_request)

```

### Drill 3: Supervision Strategies

**Task:** Match the strategy to the behavior.

1. `one_for_one`
2. `one_for_all`
3. `rest_for_one`

A. If Child B crashes, restart Child B, C, and D (but not A).
B. If Child B crashes, restart only Child B.
C. If Child B crashes, restart A, B, C, and D.

---

## 3. The Project: The Fault-Tolerant Todo System

We will refactor our system into a proper tree. This involves breaking `Todo.System` into multiple supervisors and using `Registry` for discovery.

### Step 1: The Process Registry

Create `lib/todo/process_registry.ex`.

* Use `Registry.start_link` in `start_link`.
* Define `child_spec` to run it as a supervisor/worker.
* **Key Idea:** This replaces our manual map in `Todo.Cache`.

### Step 2: The Database Supervisor

Refactor `Todo.Database` (which was a pool manager) into a **Supervisor**.

* **Type:** `Supervisor` (not GenServer).
* **Init:** Starts 3 `Todo.DatabaseWorker` processes.
* **Strategy:** `one_for_one`.
* **Worker Registration:** Modify `Todo.DatabaseWorker` to register itself in the Registry (e.g., keys `1`, `2`, `3`).

### Step 3: The Cache (Dynamic Supervisor)

Refactor `Todo.Cache` to use `DynamicSupervisor`.

* **Init:** Start as a `DynamicSupervisor`.
* **Interface:** `server_process(name)`
* Check if the process exists (via Registry or `start_child`).
* If not running, call `DynamicSupervisor.start_child` to spawn a new `Todo.Server`.


* **Server Registration:** Modify `Todo.Server` to register itself via the Registry (using the list name as the key).

### Step 4: The System Supervisor (The Root)

Refactor `Todo.System`.

* It should now supervise three children:
1. `Todo.ProcessRegistry`
2. `Todo.Database` (The supervisor, not the worker)
3. `Todo.Cache` (The dynamic supervisor)


* **Order matters:** Registry must start first!

### Step 5: Verification

1. Start the system: `Todo.System.start_link()`.
2. Start a list for "Alice".
3. Kill the "Alice" process.
4. **Test:** Does "Alice" come back with her data? (Yes, because `Todo.Server` loads from DB on init).
5. **Test:** Did the Database restart? (No, because they are isolated).

**Example Usage:**

```elixir
# 1. Start System
Todo.System.start_link()

# 2. Get Alice's PID (starts dynamically)
pid = Todo.Cache.server_process("Alice")

# 3. Add Entry
Todo.Server.add_entry(pid, %{date: ~D[2023-01-01], title: "Audit"})

# 4. Crash Alice
Process.exit(pid, :kill)

# 5. Get Alice again (New PID, but data should be there)
new_pid = Todo.Cache.server_process("Alice")
Todo.Server.entries(new_pid, ~D[2023-01-01])

```

---

### Self-Correction Checklist

* [ ] Is `Todo.Database` now a `Supervisor` module?
* [ ] Is `Todo.Cache` now a `DynamicSupervisor`?
* [ ] Are you using `{:via, Registry, ...}` tuples for finding processes instead of manual maps?
* [ ] Did you set `restart: :temporary` for `Todo.Server`? (We don't want to restart Todo Servers automatically if they crash; we let the user restart them on next access to avoid infinite crash loops on corrupt data).

---

### Ready for the next step?

We have built a robust, single-node system. But Elixir's other superpower is **Distribution**. In **Chapter 10**, we will look at **Tasks and Agents**, simpler abstractions for concurrency, before moving on to distributed systems.