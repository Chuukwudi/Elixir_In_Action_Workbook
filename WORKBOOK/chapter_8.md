This chapter covers the critical concept of **Fault Tolerance**, specifically how to detect errors, link processes, and use **Supervisors** to automatically restart parts of the system when they crash.

---

# Chapter 8: Fault Tolerance Basics

## 1. Chapter Summary

**Runtime Errors**

* **Three Types:**
* **Errors:** Typical runtime exceptions (e.g., `1/0`, `RuntimeError`). Raised via `raise/1`.
* **Exits:** Used to terminate a process. Raised via `exit/1`.
* **Throws:** Used for non-local returns (flow control). Raised via `throw/1`.


* **Handling:** Use `try ... catch`. However, the "Let It Crash" philosophy suggests avoiding defensive coding. If a process state is corrupt, it's often better to let it crash and restart with a fresh state.

**Process Links & Monitors**

* **Links (`Process.link/1`):** Bi-directional connection. If Process A dies, Process B receives an exit signal.
* *Default Behavior:* If A crashes, B crashes too (cascading failure).
* *Trapping Exits:* If B sets `Process.flag(:trap_exit, true)`, it receives the crash as a message `{:EXIT, pid, reason}` instead of crashing.


* **Monitors (`Process.monitor/1`):** Uni-directional observation. If A monitors B, and B crashes, A receives a `{:DOWN, ...}` message. A does *not* crash.

**Supervisors**

* A **Supervisor** is a process whose only job is to manage (start, stop, restart) other processes (children).
* **Strategies:**
* `one_for_one`: If a child crashes, restart *only* that child.
* *Others (covered in Ch 9):* `one_for_all`, `rest_for_one`.


* **Child Specifications:** A map defining how to start a child.
* `id`: Unique identifier.
* `start`: The function to call (e.g., `{MyModule, :start_link, [args]}`).


* **Restart Frequency:** Supervisors have a limit (e.g., 3 restarts in 5 seconds). If exceeded, the Supervisor itself crashes to prevent infinite loops.

**The "Let It Crash" Architecture**

* We link all our processes together (DatabaseWorkers -> Database -> Cache -> System).
* If *any* process crashes, the links propagate the crash up to the Supervisor.
* The Supervisor detects the crash and restarts the Cache, which restarts everything else fresh.

---

## 2. Drills

*These drills focus on the mechanics of error handling and process linking.*

### Drill 1: The Suicide Process

**Task:** Spawn a process that waits for a message `{:boom, reason}` and then exits with that reason.

* Link to it from your shell.
* Send it `{:boom, :oops}`.
* What happens to your shell process?

**Your Solution:**

```elixir
# Spawn and link
pid = spawn_link(fn ->
  receive do
    {:boom, reason} -> exit(reason)
  end
end)

# Send the crash command
send(pid, {:boom, :oops})

```

### Drill 2: Trapping Exits

**Task:** Repeat Drill 1, but make the parent process **trap exits** first.

* Print the message received when the child crashes.

**Your Solution:**

```elixir
Process.flag(:trap_exit, true)
pid = spawn_link(fn -> ... end) # Same as above
send(pid, {:boom, :oops})

receive do
  msg -> IO.inspect(msg)
end

```

### Drill 3: Child Specifications

**Task:** Write the child specification map for a `GenServer` module named `MyServer` that takes `:ok` as an argument to `start_link`.

**Your Solution:**

```elixir
%{
  id: MyServer,
  start: {MyServer, :start_link, [:ok]}
}

```

---

## 3. The Project: The Supervised Todo System

We will take the manual linking we discussed and wrap it in a proper `Supervisor`.

### Step 1: Prepare the Modules

1. **Refactor `start` to `start_link`:** Go through `Todo.Cache`, `Todo.Server`, `Todo.Database`, and `Todo.DatabaseWorker`.
* Rename `start/X` functions to `start_link/X`.
* Inside them, call `GenServer.start_link` instead of `GenServer.start`.


2. **Add `child_spec/1` (Optional):** Since we use `use GenServer`, this is auto-generated. But verify that your `start_link` arguments match what the supervisor expects (usually 1 argument).
* *Hint:* If `Todo.Cache.start_link` takes no args, change it to `def start_link(_)` so it accepts the argument ignored by the Supervisor.



### Step 2: The System Supervisor

Create a new file `lib/todo/system.ex`.

* Define a module `Todo.System`.
* Add a function `start_link/0`.
* Inside, use `Supervisor.start_link/2`.
* **Children:** A list containing just `Todo.Cache` (since the Cache starts everything else manually for now).
* **Strategy:** `:one_for_one`.



### Step 3: Verify Recovery

1. Start the system: `Todo.System.start_link()`.
2. Get the Cache PID: `Process.whereis(Todo.Cache)`.
3. Kill it: `Process.exit(pid, :kill)`.
4. Observe: The system should print "Starting to-do cache" again immediately.
5. Check: `Process.whereis(Todo.Cache)` should show a *new* PID.

### Step 4: Full Linking (Manual)

* Ensure `Todo.Cache` links to `Todo.Server`s (using `start_link`).
* Ensure `Todo.Server` links to `Todo.Database` (if it starts it).
* *Note:* In this chapter, we are using a "naive" supervision tree where the Cache manually starts other processes. In Chapter 9, we will fix this to make it a true Supervision Tree.

**Example Usage:**

```elixir
# Start the supervisor
Todo.System.start_link()

# Interact normally
pid = Todo.Cache.server_process("Alice")
Todo.Server.add_entry(pid, %{date: ~D[2023-01-01], title: "Persist me"})

# Kill the database process
db_pid = Process.whereis(Todo.Database)
Process.exit(db_pid, :kill)

# The whole system should restart
# Try to get Alice's list again (it should work, loaded from disk)
pid = Todo.Cache.server_process("Alice")
Todo.Server.entries(pid, ~D[2023-01-01])

```

---

### Self-Correction Checklist

* [ ] Did you rename *all* `start` functions to `start_link`?
* [ ] Did you change `GenServer.start` to `GenServer.start_link` everywhere?
* [ ] does `Todo.System.start_link` return `{:ok, pid}`?

---

### Ready for the next step?

We have basic fault tolerance, but restarting the *entire* system just because one worker crashed is inefficient. In **Chapter 9**, we will build **Isolation**. We will construct a proper **Supervision Tree** where crashes are contained, and only the affected parts of the system restart.