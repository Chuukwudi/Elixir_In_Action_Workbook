This chapter is the point where you stop writing "manual" concurrency (like `spawn`, `send`, `receive`) and start using the **Industry Standard**: `GenServer`. This is the most critical chapter for writing production-ready Elixir code.

---

# Chapter 6: Generic Server Processes (GenServer)

## 1. Chapter Summary

**The "Generic Server" Pattern**
In Chapter 5, we wrote a `TodoServer` loop manually. It turns out that *every* server process needs to do the same boilerplate tasks:

1. Spawn a separate process.
2. Run an infinite loop.
3. Manage the state.
4. React to messages (requests).
5. Send responses back to callers.

**OTP Behaviours**
Erlang/OTP solves this by providing **Behaviours**. A behaviour is "Generic Code" (the engine) that accepts a "Callback Module" (the plug-in).

* **The Engine:** `GenServer` (manages the loop, the mailbox, timeouts, error propagation).
* **The Plug-in:** *Your Module* (defines `init`, `handle_call`, `handle_cast`).

**Key GenServer Callbacks**
When you write `use GenServer` in your module, you are implementing these callbacks:

* **`init/1`:** Invoked when the server starts. Returns `{:ok, initial_state}`.
* **`handle_call/3`:** Handles **Synchronous** requests (expects a response). Returns `{:reply, response, new_state}`.
* The client *waits* for this response (default timeout: 5s).


* **`handle_cast/2`:** Handles **Asynchronous** requests (fire-and-forget). Returns `{:noreply, new_state}`.
* The client returns `:ok` immediately and does not wait.


* **`handle_info/2`:** Handles messages sent to the process that are *not* GenServer-specific (e.g., `send(pid, :work)` or `Process.send_after`). Returns `{:noreply, new_state}`.

**Process Life Cycle** 

1. **Client:** Calls `GenServer.start(MyModule, args)`.
2. **GenServer:** Spawns a process.
3. **Process:** Runs `MyModule.init(args)` to set up state.
4. **Process:** Enters the receive loop.
5. **Loop:** Waits for messages. When one arrives, it calls the appropriate `handle_*` function in `MyModule`.

---

## 2. Drills

*These drills focus on the syntax of the GenServer callbacks.*

### Drill 1: Synchronous Math (Again)

**Task:** Implement a GenServer that stores a number and adds to it.

* **Interface:** `add(pid, number)` -> returns the *new total*.
* **Callback:** Which callback should you use? (`handle_call` or `handle_cast`?)

**Your Solution:**

```elixir
defmodule Calculator do
  use GenServer

  # Interface
  def add(pid, number), do: GenServer.call(pid, {:add, number})

  # Callback
  def handle_call({:add, number}, _from, state) do
    new_state = state + number
    # Return {:reply, RESPONSE, NEW_STATE}
    {:reply, new_state, new_state}
  end
end

```

### Drill 2: Asynchronous Logging

**Task:** Implement a GenServer that accepts log messages and prints them. The client should **not** wait for the printing to finish.

* **Interface:** `log(pid, message)`.
* **Callback:** Which callback?

**Your Solution:**

```elixir
defmodule Logger do
  use GenServer

  def log(pid, msg), do: GenServer.cast(pid, {:log, msg})

  def handle_cast({:log, msg}, state) do
    IO.puts(msg)
    {:noreply, state}
  end
end

```

### Drill 3: Periodic Tasks (`handle_info`)

**Task:** Write the `init` function for a GenServer that sends *itself* a message `:tick` every 5 seconds.

* 
**Hint:** Use `:timer.send_interval/2`.



**Your Solution:**

```elixir
def init(_args) do
  :timer.send_interval(5000, :tick)
  {:ok, %{}}
end

def handle_info(:tick, state) do
  IO.puts("Tick!")
  {:noreply, state}
end

```

---

## 3. The Project: The GenServer Todo List

We will refactor our `TodoServer` from Chapter 5 to use `GenServer`. This drastically reduces the amount of code we need to write and makes it safer.

**Goal:** Create `TodoServer` using `use GenServer`.

### Step 1: Initialization

* Use `GenServer.start/3` (often wrapped in a `start/0` function).
* Implement `init/1`. It should return `{:ok, TodoList.new()}`.

### Step 2: Add Entry (Cast)

* **Interface:** `add_entry(pid, entry)`. Use `GenServer.cast`.
* **Callback:** `handle_cast({:add_entry, entry}, state)`.
* Update the state using `TodoList.add_entry`.
* Return `{:noreply, new_state}`.



### Step 3: Get Entries (Call)

* **Interface:** `entries(pid, date)`. Use `GenServer.call`.
* **Callback:** `handle_call({:entries, date}, _from, state)`.
* Retrieve entries using `TodoList.entries`.
* Return `{:reply, entries, state}`. (Note: The state itself doesn't change here).



### Step 4: Named Process (Registration)

* Modify your `start` function to register the process globally as `TodoServer` (or `__MODULE__`).
* 
**Hint:** `GenServer.start(__MODULE__, nil, name: __MODULE__)`.


* Update your interface functions (`add_entry`, `entries`) to use `__MODULE__` instead of `pid`.

### Step 5: Verification

Run the following in `iex`:

```elixir
TodoServer.start()
TodoServer.add_entry(%{date: ~D[2023-01-01], title: "Refactor to GenServer"})
TodoServer.entries(~D[2023-01-01])
# Should return the list with the entry

```

---

### Self-Correction Checklist

* [ ] Did you use `{:reply, response, state}` for calls?
* [ ] Did you use `{:noreply, state}` for casts?
* [ ] Did you remember that `handle_call` takes **3** arguments (request, from, state) but `handle_cast` takes **2**?

---

### Ready for the next step?

Now that you have a robust server, you might be wondering: "What if I need **multiple** Todo Lists? Or what if I want to persist this data to disk?" In **Chapter 7**, we will build a **System** of processes (a "Pool") to handle multiple lists simultaneously.
