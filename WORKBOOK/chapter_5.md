This chapter deals with **Concurrency Primitives**—processes, message passing, and state. We are now working at the VM level, using the `spawn`, `send`, and `receive` functions that power the entire Elixir ecosystem.

---

# Chapter 5: Concurrency Primitives

## 1. Chapter Summary

**The BEAM Process Model**

* **Processes != OS Processes:** BEAM processes are tiny (~2KB memory footprint). You can spawn millions of them.
* **Shared Nothing:** Processes are completely isolated. They do not share memory. If Process A wants to send data to Process B, that data is **deep copied**. * **Scheduling:** The BEAM uses one scheduler per CPU core. These schedulers are preemptive—processes get a small time slice (~2,000 reductions) before yielding, ensuring that one heavy calculation doesn't block the whole system. 



**Message Passing (`send` and `receive`)**

* **Sending:** `send(pid, message)` is asynchronous ("fire and forget"). It puts a message in the recipient's mailbox and returns immediately.
* **Receiving:** `receive do ... end` pulls one message from the mailbox. It uses pattern matching to decide how to handle it. If no message matches, it stays in the mailbox.
* **Mailboxes:** Every process has a mailbox. It is a FIFO queue.

**Stateful Server Processes**

* Since data is immutable, how do we keep state (like a counter or a Todo list)? We use **infinite recursion**.
* **The Loop Pattern:**
1. Wait for a message (`receive`).
2. Calculate the new state based on the message.
3. Call the loop function recursively with the **new state**.


* This effectively turns a process into a mutable container for immutable data.

**Synchronous Communication**

* There is no built-in "request/response" primitive. We build it manually:
1. Client sends: `{self(), :request_type, data}`.
2. Server processes request and sends back: `send(caller_pid, {:response, result})`.
3. Client waits in a `receive` block for the response.



---

## 2. Drills

*These drills practice the raw concurrency syntax.*

### Drill 1: The Echo Process

**Task:** Spawn a process that waits for a message. When it receives a message `{:echo, text}`, it should print `text` to the console.

**Your Solution:**

```elixir
pid = spawn(fn ->
  receive do
    # ... fill in the pattern match
  end
end)

send(pid, {:echo, "Hello World"})

```

### Drill 2: Synchronous Math

**Task:** Write a client function `double(server_pid, number)` that asks a server process to multiply a number by 2 and **returns** the result to the caller.

**Your Solution:**

```elixir
def double(server_pid, number) do
  send(server_pid, {self(), number})
  receive do
    # ... wait for the response and return it
  end
end

```

### Drill 3: Registered Processes

**Task:** Instead of passing PIDs around, register the current process as `:my_server`. Then send a message to it using the name instead of the PID.

**Your Solution:**

```elixir
Process.register(self(), :my_server)
# ... write the send command

```

---

## 3. The Project: The Stateful Todo Server

We will take the functional `TodoList` structure from Chapter 4 and wrap it in a **Stateful Server Process**. This allows the list to persist in memory and be updated by multiple clients.

**Goal:** Create a `TodoServer` module that hides the `spawn`, `send`, and `receive` logic from the user.

### Step 1: The Loop

Create a private `loop/1` function.

* **Input:** `todo_list` (the current state).
* **Behavior:**
1. Wait for a message.
2. Handle `{:add_entry, new_entry}`: Update the list and recurse with the new list.
3. Handle `{:entries, caller, date}`: Read the list, send the result back to `caller`, and recurse with the *same* list.
4. Handle unknown messages: Print an error and recurse.



### Step 2: The Interface (Start)

Create a `start/0` function.

* It should `spawn` the `loop/1` function, initializing it with `TodoList.new()`.
* It should return the PID.

### Step 3: The Interface (Add)

Create `add_entry(server_pid, entry)`.

* It should send a message to the server.
* It is asynchronous (returns `:ok` immediately).

### Step 4: The Interface (Read)

Create `entries(server_pid, date)`.

* It should send a request (including `self()`).
* It should wait (`receive`) for the response and return the list of entries.
* **Timeout:** Add an `after 5000` clause to the receive block so the client doesn't hang forever if the server crashes.

### Step 5: Refactoring (Optional)

Refactor your loop to use a `process_message/2` helper function (as shown in the book) to separate the *message handling logic* from the *looping mechanics*.

**Example Usage:**

```elixir
pid = TodoServer.start()
TodoServer.add_entry(pid, %{date: ~D[2023-01-01], title: "Happy New Year"})
entries = TodoServer.entries(pid, ~D[2023-01-01])
# => [%{title: "Happy New Year", ...}]

```

---

### Self-Correction Checklist

* [ ] Did you use `spawn(fn -> loop(...) end)` to start the process?
* [ ] Does your loop function call itself recursively at the end of *every* receive clause? (If not, the process will die after one message).
* [ ] Did you remember to send `self()` in the read request?

---

### Ready for the next step?

In **Chapter 6**, we will stop writing this manual loop/receive code. We will introduce **GenServer** (Generic Server), the battle-tested standard library that handles all this boilerplate (timeouts, error handling, synchronous calls) for us.