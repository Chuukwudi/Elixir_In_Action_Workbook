# Chapter 12: Building a Distributed System - Learning Exercises

## Chapter Summary

Chapter 12 explores BEAM's built-in distribution primitives that enable building fault-tolerant clusters across multiple nodes. By leveraging familiar concepts like processes and message passing—extended across network boundaries with location transparency—you can create distributed systems where nodes share workload, survive individual machine failures, and scale horizontally. The chapter covers starting and connecting nodes, process discovery mechanisms (`:global` for cluster-wide registration, `:pg` for process groups), distributed links and monitors, and implementing a replicated database, while acknowledging the challenges of network partitions and providing strategies for building resilient distributed applications.

---

## Concept Drills

### Drill 1: Starting and Connecting Nodes

**Objective:** Understand how to create a BEAM cluster.

**Task:** Start multiple nodes and connect them:

```bash
# Terminal 1
$ iex --sname node1@localhost

# Terminal 2
$ iex --sname node2@localhost

# Terminal 3
$ iex --sname node3@localhost
```

**Connect the nodes:**
```elixir
# On node2
iex(node2@localhost)> Node.connect(:node1@localhost)
true

# On node3
iex(node3@localhost)> Node.connect(:node2@localhost)
true
```

**Exercises:**
1. Check connected nodes: `Node.list/0`
2. Get all nodes including current: `Node.list([:this, :visible])`
3. What is your current node name? `node/0`
4. Disconnect node3: `Node.disconnect(:node3@localhost)`
5. What happens to the cluster?

**Expected Behavior:**
- Connecting to one node connects to all (fully connected cluster)
- `Node.list/0` shows all connected nodes except current
- Disconnection removes node from all connected nodes

---

### Drill 2: Message Passing Across Nodes

**Objective:** Send messages between processes on different nodes.

**Task:** Spawn processes and communicate across nodes:

```elixir
# On node1 - capture caller PID
iex(node1@localhost)> caller = self()

# Spawn on node2, send back a message
iex(node1@localhost)> Node.spawn(:node2@localhost, fn ->
  send(caller, {:hello, node()})
end)

# Check messages
iex(node1@localhost)> flush()
{:hello, :node2@localhost}
```

**More Examples:**
```elixir
# Remote calculation
iex(node1@localhost)> Node.spawn(:node2@localhost, fn ->
  result = Enum.sum(1..1_000_000)
  send(caller, {:result, result})
end)

iex(node1@localhost)> receive do
  {:result, sum} -> IO.puts("Sum: #{sum}")
end
```

**Exercises:**
1. Spawn a process on node2 that computes factorial of 10
2. Send the result back to node1
3. Spawn processes on all nodes in the cluster
4. Collect results from all nodes
5. What happens if you send a large data structure?

**Key Concepts:**
- Closures work across nodes
- Messages are serialized with `:erlang.term_to_binary/1`
- Location transparency - same API for local and remote

---

### Drill 3: Global Process Registration

**Objective:** Use `:global` for cluster-wide process names.

**Task:** Register processes globally:

```elixir
# On node1
iex(node1@localhost)> :global.register_name(:counter, self())
:yes

# On node2 - try to register same name
iex(node2@localhost)> :global.register_name(:counter, self())
:no

# On node2 - find the globally registered process
iex(node2@localhost)> pid = :global.whereis_name(:counter)
#PID<7954.90.0>

# Send message to globally registered process
iex(node2@localhost)> send(pid, :hello)

# On node1
iex(node1@localhost)> flush()
:hello
```

**Build a Distributed Counter:**
```elixir
defmodule DistributedCounter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, 0, name: {:global, __MODULE__})
  end

  def increment do
    GenServer.cast({:global, __MODULE__}, :increment)
  end

  def get do
    GenServer.call({:global, __MODULE__}, :get)
  end

  @impl GenServer
  def init(count), do: {:ok, count}

  @impl GenServer
  def handle_cast(:increment, count) do
    {:noreply, count + 1}
  end

  @impl GenServer
  def handle_call(:get, _from, count) do
    {:reply, count, count}
  end
end
```

**Test:**
```elixir
# On any node
DistributedCounter.start_link()

# From different nodes
DistributedCounter.increment()
DistributedCounter.increment()
DistributedCounter.get()  # => 2
```

**Questions:**
1. What happens if the process crashes?
2. Can you register the same name twice?
3. What's the performance impact of global registration?
4. How is `:global.whereis_name/1` different from registration?

---

### Drill 4: Process Groups with :pg

**Objective:** Use `:pg` for cluster-wide process groups.

**Task:** Create and manage process groups:

```elixir
# Start :pg on all nodes
iex(node1@localhost)> :pg.start_link()
iex(node2@localhost)> :pg.start_link()

# Join processes to a group
iex(node1@localhost)> :pg.join(:workers, self())
iex(node2@localhost)> :pg.join(:workers, self())

# Get all members from any node
iex(node1@localhost)> :pg.get_members(:workers)
[#PID<8531.90.0>, #PID<0.90.0>]

# Send to all members
iex(node1@localhost)> for pid <- :pg.get_members(:workers) do
  send(pid, {:broadcast, "Hello everyone"})
end
```

**Build a Pub-Sub System:**
```elixir
defmodule PubSub do
  def subscribe(topic) do
    :pg.start_link()
    :pg.join(topic, self())
  end

  def publish(topic, message) do
    for pid <- :pg.get_members(topic) do
      send(pid, {:message, topic, message})
    end
  end

  def unsubscribe(topic) do
    :pg.leave(topic, self())
  end
end
```

**Test:**
```elixir
# Node1
PubSub.subscribe(:news)

# Node2
PubSub.subscribe(:news)
PubSub.publish(:news, "Breaking: Elixir is awesome!")

# Both nodes receive the message
flush()
{:message, :news, "Breaking: Elixir is awesome!"}
```

---

### Drill 5: Distributed Links and Monitors

**Objective:** Understand error propagation across nodes.

**Task:** Monitor processes on remote nodes:

```elixir
# On node1 - start a process
iex(node1@localhost)> pid = spawn(fn ->
  receive do
    :stop -> :ok
  end
end)

# On node2 - monitor the remote process
iex(node2@localhost)> ref = Process.monitor(pid)

# On node1 - stop the process
iex(node1@localhost)> send(pid, :stop)

# On node2 - check for DOWN message
iex(node2@localhost)> flush()
{:DOWN, #Reference<...>, :process, #PID<7954.123.0>, :normal}
```

**Node Disconnection:**
```elixir
# Monitor a process
ref = Process.monitor(remote_pid)

# Disconnect or crash the remote node

# Receive notification
flush()
{:DOWN, #Reference<...>, :process, #PID<...>, :noconnection}
```

**Exercises:**
1. Link two processes on different nodes
2. Crash one - what happens to the other?
3. Monitor a node: `Node.monitor(:node2@localhost, true)`
4. Disconnect the node - what message do you receive?
5. What's the difference between links and monitors in distributed systems?

---

### Drill 6: Remote Procedure Calls

**Objective:** Use `:rpc` for function calls across nodes.

**Task:** Execute functions on remote nodes:

```elixir
# Simple RPC
iex(node1@localhost)> :rpc.call(:node2@localhost, Kernel, :node, [])
:node2@localhost

# With arguments
iex(node1@localhost)> :rpc.call(
  :node2@localhost,
  Enum,
  :sum,
  [1..1000]
)
500500

# Multi-call to all nodes
iex(node1@localhost)> :rpc.multicall(
  [node()| Node.list()],
  System,
  :schedulers_online,
  []
)
{[8, 8, 8], []}  # results from all nodes
```

**Error Handling:**
```elixir
# Call non-existent function
:rpc.call(:node2@localhost, NonExistent, :foo, [])
# => {:badrpc, :EXIT, ...}

# Call on disconnected node
:rpc.call(:offline_node@localhost, Kernel, :node, [])
# => {:badrpc, :nodedown}
```

**Use Cases:**
- Cluster-wide operations
- Health checks
- Metrics collection
- Administrative commands

---

### Drill 7: Distribution Gotchas

**Objective:** Understand limitations and pitfalls.

**Task:** Explore what works and what doesn't:

**Don't Send Lambdas:**
```elixir
# BAD - shell lambdas work, module lambdas don't always
Node.spawn(:node2@localhost, fn -> IO.puts("Works in shell") end)

# GOOD - use MFA (Module, Function, Args)
Node.spawn(:node2@localhost, IO, :puts, ["Always works"])
```

**PID Representation:**
```elixir
# Local process
local_pid = self()
# => #PID<0.123.0>  (first number is 0)

# Remote process
remote_pid = :rpc.call(:node2@localhost, Kernel, :self, [])
# => #PID<7954.123.0>  (first number != 0)

# Check if remote
Kernel.node(local_pid)   # => :node1@localhost
Kernel.node(remote_pid)  # => :node2@localhost
```

**Message Size:**
```elixir
# Large messages = expensive
big_data = :binary.copy("x", 10_000_000)  # 10 MB
send(remote_pid, big_data)  # Serializes and sends over network
```

**Cookie Security:**
```elixir
# Nodes must have same cookie to connect
Node.get_cookie()  # => :some_atom
Node.set_cookie(:node2@localhost, :different_cookie)
Node.connect(:node2@localhost)  # => false
```

---

## Integration Exercises

### Exercise 1: Distributed KV Store

**Objective:** Build a replicated key-value store across nodes.

**Concepts Reinforced:**
- Global registration (Chapter 12)
- GenServer (Chapter 6)
- ETS tables (Chapter 10)
- Process discovery (Chapter 12)

**Task:**

```elixir
defmodule DistributedKV do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def put(key, value) do
    GenServer.call({:global, __MODULE__}, {:put, key, value})
  end

  def get(key) do
    GenServer.call({:global, __MODULE__}, {:get, key})
  end

  def get_local(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :not_found
    end
  end

  ## Callbacks

  @impl GenServer
  def init(_) do
    :ets.new(__MODULE__, [:named_table, :public, :set])
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:put, key, value}, _from, state) do
    # Store locally
    :ets.insert(__MODULE__, {key, value})

    # Replicate to all nodes
    for node <- Node.list() do
      :rpc.call(node, :ets, :insert, [__MODULE__, {key, value}])
    end

    {:reply, :ok, state}
  end

  def handle_call({:get, key}, _from, state) do
    result = case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:ok, value}
      [] -> :not_found
    end
    {:reply, result, state}
  end
end
```

**Requirements:**
1. Single writer (uses :global)
2. Replicated reads (local ETS on each node)
3. Writes propagate to all nodes
4. Reads are local (no network calls)
5. Handle node disconnections

**Test:**
```elixir
# Start on all nodes
DistributedKV.start_link()

# Write from node1
DistributedKV.put(:user_1, "Alice")

# Read from node2 (local)
DistributedKV.get_local(:user_1)
# => {:ok, "Alice"}
```

---

### Exercise 2: Distributed Task Queue

**Objective:** Build a work-stealing task queue.

**Concepts Reinforced:**
- Process groups (Chapter 12)
- Dynamic supervision (Chapter 9)
- Tasks (Chapter 10)

**Task:**

```elixir
defmodule DistributedQueue do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def enqueue(task) do
    # Pick a random node
    nodes = [node() | Node.list()]
    target = Enum.random(nodes)

    :rpc.call(target, GenServer, :cast, [__MODULE__, {:enqueue, task}])
  end

  def start_worker do
    GenServer.call(__MODULE__, :start_worker)
  end

  @impl GenServer
  def init(_) do
    :pg.start_link()
    :pg.join(:queue_workers, self())

    {:ok, %{queue: :queue.new(), workers: 0}}
  end

  @impl GenServer
  def handle_cast({:enqueue, task}, state) do
    new_queue = :queue.in(task, state.queue)
    process_queue(%{state | queue: new_queue})
  end

  @impl GenServer
  def handle_call(:start_worker, _from, state) do
    case :queue.out(state.queue) do
      {{:value, task}, new_queue} ->
        spawn_worker(task)
        {:reply, :ok, %{state | queue: new_queue, workers: state.workers + 1}}

      {:empty, _} ->
        {:reply, :empty, state}
    end
  end

  @impl GenServer
  def handle_info({:worker_done, _result}, state) do
    new_state = %{state | workers: state.workers - 1}
    process_queue(new_state)
  end

  defp process_queue(state) do
    if state.workers < 5 and not :queue.is_empty(state.queue) do
      {{:value, task}, new_queue} = :queue.out(state.queue)
      spawn_worker(task)
      {:noreply, %{state | queue: new_queue, workers: state.workers + 1}}
    else
      {:noreply, state}
    end
  end

  defp spawn_worker(task) do
    parent = self()
    spawn(fn ->
      result = execute_task(task)
      send(parent, {:worker_done, result})
    end)
  end

  defp execute_task(task) do
    Process.sleep(1000)
    {:ok, "Processed: #{task}"}
  end
end
```

---

### Exercise 3: Distributed Lock Manager

**Objective:** Implement cluster-wide resource locking.

**Concepts Reinforced:**
- :global locks (Chapter 12)
- GenServer (Chapter 6)
- Supervision (Chapter 9)

**Task:**

```elixir
defmodule LockManager do
  def acquire(resource, timeout \\ 5000) do
    lock_id = {resource, self()}

    if :global.set_lock(lock_id, [node() | Node.list()], timeout) do
      {:ok, lock_id}
    else
      {:error, :timeout}
    end
  end

  def release(lock_id) do
    :global.del_lock(lock_id, [node() | Node.list()])
  end

  def with_lock(resource, fun, timeout \\ 5000) do
    case acquire(resource, timeout) do
      {:ok, lock_id} ->
        try do
          fun.()
        after
          release(lock_id)
        end

      {:error, :timeout} = error ->
        error
    end
  end
end
```

**Usage:**
```elixir
# From any node
LockManager.with_lock(:database, fn ->
  IO.puts("I have exclusive access")
  # Do critical work
end)
```

---

## Capstone Project: Fault-Tolerant Distributed Chat System

### Project Description

Build a complete distributed chat application that survives node failures, replicates messages across the cluster, and provides real-time communication between users on different nodes.

### Architecture

```
ChatSystem
├── ChatSystem.Application
│   ├── ChatSystem.Registry (global user registry)
│   ├── ChatSystem.RoomSupervisor (dynamic rooms)
│   ├── ChatSystem.UserSupervisor (dynamic users)
│   └── ChatSystem.MessageStore (replicated storage)
```

### Requirements

#### 1. User Management

```elixir
defmodule ChatSystem.User do
  use GenServer

  def start_link(username) do
    GenServer.start_link(
      __MODULE__,
      username,
      name: {:global, {:user, username}}
    )
  end

  def send_message(username, message) do
    GenServer.cast({:global, {:user, username}}, {:message, message})
  end

  def join_room(username, room_name) do
    GenServer.call({:global, {:user, username}}, {:join_room, room_name})
  end

  @impl GenServer
  def init(username) do
    {:ok, %{username: username, rooms: [], messages: []}}
  end

  @impl GenServer
  def handle_cast({:message, message}, state) do
    IO.puts("[#{state.username}] #{message}")
    new_messages = [message | Enum.take(state.messages, 99)]
    {:noreply, %{state | messages: new_messages}}
  end

  @impl GenServer
  def handle_call({:join_room, room_name}, _from, state) do
    ChatSystem.Room.add_user(room_name, state.username)
    {:reply, :ok, %{state | rooms: [room_name | state.rooms]}}
  end
end
```

#### 2. Chat Rooms with Replication

```elixir
defmodule ChatSystem.Room do
  use GenServer

  def start_link(room_name) do
    GenServer.start_link(
      __MODULE__,
      room_name,
      name: {:global, {:room, room_name}}
    )
  end

  def add_user(room_name, username) do
    GenServer.call({:global, {:room, room_name}}, {:add_user, username})
  end

  def broadcast(room_name, from_user, message) do
    GenServer.cast({:global, {:room, room_name}}, {:broadcast, from_user, message})
  end

  def list_users(room_name) do
    GenServer.call({:global, {:room, room_name}}, :list_users)
  end

  @impl GenServer
  def init(room_name) do
    :pg.start_link()
    :pg.join({:room_replica, room_name}, self())

    state = %{
      name: room_name,
      users: MapSet.new(),
      message_history: []
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:add_user, username}, _from, state) do
    new_users = MapSet.put(state.users, username)
    replicate_state({:add_user, username})
    {:reply, :ok, %{state | users: new_users}}
  end

  def handle_call(:list_users, _from, state) do
    {:reply, MapSet.to_list(state.users), state}
  end

  @impl GenServer
  def handle_cast({:broadcast, from_user, message}, state) do
    # Store message
    msg = %{from: from_user, text: message, timestamp: System.system_time()}
    new_history = [msg | Enum.take(state.message_history, 99)]

    # Replicate
    replicate_state({:broadcast, from_user, message})

    # Send to all users
    for username <- state.users do
      ChatSystem.User.send_message(username, "[#{from_user}]: #{message}")
    end

    {:noreply, %{state | message_history: new_history}}
  end

  defp replicate_state(operation) do
    replicas = :pg.get_members({:room_replica, state.name})
    for replica <- replicas, replica != self() do
      GenServer.cast(replica, {:replicate, operation})
    end
  end

  @impl GenServer
  def handle_cast({:replicate, {:add_user, username}}, state) do
    new_users = MapSet.put(state.users, username)
    {:noreply, %{state | users: new_users}}
  end

  def handle_cast({:replicate, {:broadcast, from_user, message}}, state) do
    msg = %{from: from_user, text: message, timestamp: System.system_time()}
    new_history = [msg | Enum.take(state.message_history, 99)]
    {:noreply, %{state | message_history: new_history}}
  end
end
```

#### 3. Message Store with Replication

```elixir
defmodule ChatSystem.MessageStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def store_message(room, message) do
    # Store on all nodes
    for node <- [node() | Node.list()] do
      :rpc.call(node, __MODULE__, :store_local, [room, message])
    end
  end

  def store_local(room, message) do
    :ets.insert(__MODULE__, {{room, System.unique_integer()}, message})
  end

  def get_history(room, limit \\ 100) do
    pattern = {{room, :"$1"}, :"$2"}
    :ets.select(__MODULE__, [{pattern, [], [{{:"$1", :"$2"}}]}])
    |> Enum.sort_by(fn {id, _} -> -id end)
    |> Enum.take(limit)
    |> Enum.map(fn {_, msg} -> msg end)
  end

  @impl GenServer
  def init(_) do
    :ets.new(__MODULE__, [:named_table, :public, :bag])
    {:ok, %{}}
  end
end
```

#### 4. Node Failure Detection

```elixir
defmodule ChatSystem.ClusterMonitor do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, %{nodes: Node.list()}}
  end

  @impl GenServer
  def handle_info({:nodeup, node}, state) do
    IO.puts("Node joined: #{node}")
    # Sync state with new node
    ChatSystem.sync_with_node(node)
    {:noreply, %{state | nodes: [node | state.nodes]}}
  end

  def handle_info({:nodedown, node}, state) do
    IO.puts("Node left: #{node}")
    # Handle failover
    ChatSystem.handle_node_failure(node)
    {:noreply, %{state | nodes: List.delete(state.nodes, node)}}
  end
end
```

### Testing Scenarios

```elixir
# Start on node1
$ iex --sname node1@localhost -S mix

# Start on node2
$ iex --sname node2@localhost -S mix
iex> Node.connect(:node1@localhost)

# Create users
iex> ChatSystem.User.start_link("Alice")  # on node1
iex> ChatSystem.User.start_link("Bob")    # on node2

# Create room
iex> ChatSystem.Room.start_link("general")

# Join room
iex> ChatSystem.User.join_room("Alice", "general")
iex> ChatSystem.User.join_room("Bob", "general")

# Send messages
iex> ChatSystem.Room.broadcast("general", "Alice", "Hello!")
# => Bob receives: [Alice]: Hello!

# Kill node1, verify Bob still in room on node2
# Restart node1, verify state recovers
```

### Bonus Challenges

1. **Private Messages** - Direct user-to-user messaging
2. **Presence** - Track online/offline status
3. **Typing Indicators** - Show when users are typing
4. **File Sharing** - Distribute files across nodes
5. **Search** - Search message history across cluster
6. **Encryption** - End-to-end encryption for messages

### Evaluation Criteria

**Distribution (30 points)**
- Proper node connectivity (5 pts)
- Global registration (10 pts)
- Process groups usage (10 pts)
- RPC usage (5 pts)

**Fault Tolerance (25 points)**
- Handles node failures (10 pts)
- Message replication (10 pts)
- Recovery mechanisms (5 pts)

**Features (25 points)**
- User management (10 pts)
- Room functionality (10 pts)
- Message delivery (5 pts)

**Code Quality (20 points)**
- Clean architecture (10 pts)
- Error handling (5 pts)
- Documentation (5 pts)

---

## Success Checklist

Before moving to Chapter 13, ensure you can:

- [ ] Start named nodes with --sname
- [ ] Connect nodes with Node.connect/1
- [ ] Send messages across nodes
- [ ] Use location transparency
- [ ] Register processes globally with :global
- [ ] Use :pg for process groups
- [ ] Perform distributed RPC calls
- [ ] Monitor remote processes
- [ ] Handle node disconnections
- [ ] Understand network partition challenges
- [ ] Use :global locks judiciously
- [ ] Avoid sending lambdas between nodes
- [ ] Design for fault tolerance
- [ ] Implement replication strategies

---

## Looking Ahead

Chapter 13 covers running systems in production:
- **OTP Releases** - Building standalone packages
- **Deployment** - Production deployment strategies
- **Monitoring** - Observing running systems
- **Debugging** - Troubleshooting in production

The final chapter brings everything together for production-ready distributed systems!
