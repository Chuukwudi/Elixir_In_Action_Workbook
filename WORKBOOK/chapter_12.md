This chapter unlocks the final "superpower" of the BEAM: **Distribution**. You will learn that a distributed system in Elixir is just a concurrent system that spans multiple computers. The primitives (`send`, `spawn`, `monitor`) work exactly the same way across the network as they do locally.

---

# Chapter 12: Building a Distributed System

## 1. Chapter Summary

**The Distributed Model**

* **Nodes:** A "Node" is a running BEAM instance with a name (e.g., `alice@localhost`).
* **Cookies:** Security is based on a shared secret "cookie". Nodes must share the same cookie to talk.
* **Fully Meshed:** By default, if Node A connects to Node B, and Node B connects to Node C, then A and C automatically connect. Everyone talks to everyone.

**Distribution Primitives**

* **Location Transparency:** `send(pid, msg)` works exactly the same whether `pid` is local or on a remote server. You don't need special "RPC" libraries; message passing *is* the RPC.
* **Remote Messaging:** You can send a message to a registered process on another node using the tuple syntax: `send({:process_name, :remote_node@host}, :message)`.
* **Remote Spawn:** `Node.spawn(node, lambda)` runs code on another machine. *Caveat:* The compiled code for that lambda must exist on the target machine.

**Process Discovery**

* **Local Registry:** (What we used in Ch 9). Good for one machine.
* **`:global`:** An Erlang module that maintains a global name registry across the entire cluster. It uses locks to ensure a name exists on only *one* node at a time. Good for singletons (e.g., "The Payment Processor").
* **`:pg` (Process Groups):** Allows registering *multiple* processes under one name. Good for pub/sub (e.g., "Send this to all 'chat_room_1' processes").

**Replication & Fault Tolerance**

* **Cluster-wide storage:** To survive a node crash, data must be replicated.
* **Naive Replication:** We can use `:rpc.multicall` to execute a function (like `db_store`) on *all* connected nodes simultaneously.

**Networking Realities**

* **EPMD:** The Erlang Port Mapper Daemon acts as a DNS for BEAM nodes on a single machine.
* **Firewalls:** Distribution uses random ports by default. For production, you must configure a specific port range (`inet_dist_listen_min/max`).
* **Netsplits:** Networks fail. If the connection breaks, you might end up with two isolated clusters ("Split Brain").

---

## 2. Drills

*These drills require you to open two terminal windows.*

### Drill 1: The Handshake

**Task:**

1. **Terminal 1:** Start `iex --sname node1`.
2. **Terminal 2:** Start `iex --sname node2`.
3. **Action:** Connect `node2` to `node1`.
4. **Verify:** Run `Node.list()` in both terminals.

**Your Solution:**

```elixir
# In Terminal 2:
Node.connect(:node1@HOSTNAME) # Replace HOSTNAME with your machine name (shown in the prompt)

```

### Drill 2: Remote Control

**Task:** From `node2`, spawn a process on `node1` that prints "Hello from [Node Name]" to the console.
*Hint:* Use `Node.spawn/2` and `Node.self/0`.

**Your Solution:**

```elixir
# In Terminal 2:
Node.spawn(:node1@HOSTNAME, fn ->
  IO.puts("Hello from #{Node.self()}")
end)

```

### Drill 3: The Global Lock

**Task:**

1. Connect the nodes.
2. In `node1`: Register the shell process globally as `:boss`.
3. In `node2`: Try to register the shell process globally as `:boss`. What happens?
4. In `node2`: Send a message to `:boss` using `:global.send/2`.

**Your Solution:**

```elixir
# Node 1
:global.register_name(:boss, self())

# Node 2
:global.register_name(:boss, self()) # Should return :no
:global.send(:boss, "I surrender")

```

---

## 3. The Project: The Distributed Todo Cluster

We will transform our single-node system into a cluster. We want to be able to access "Alice's List" from *any* node, and have the data backed up on *all* nodes.

### Step 1: Global Registration (`Todo.Server`)

In Chapter 9, we used `Registry` (local) to find Todo Servers. Now we need to find them across the cluster.

* **Refactor:** Modify `Todo.Server` to use `:global` instead of `Todo.ProcessRegistry`.
* **Note:** `:global` expects a tuple name like `{:todo_list, "Alice"}`.


* **Remove:** You can delete `Todo.ProcessRegistry` from your supervision tree and code. We don't need it anymore.

### Step 2: Global Discovery (`Todo.Cache`)

Update `Todo.Cache` to find processes globally.

* **Check:** Use `:global.whereis_name({:todo_list, name})`.
* **Start:** If not found, start the child via `DynamicSupervisor`.
* **Bottleneck Warning:** Global registration involves "chatter" between nodes. It is slower than local registration but simpler for this stage.

### Step 3: Database Replication

We want data to be saved on *all* nodes, so if one crashes, the data persists.

* **Refactor `Todo.Database`:**
* Rename `store` to `store_local`.
* Create a new `store` function that uses `:rpc.multicall`.
* **Logic:** `store` should call `store_local` on *all* nodes in the cluster (including itself).
* **File Paths:** Ensure your database workers store files in a folder unique to the node (e.g., `persist/node1/`), or you will get file conflicts when running locally. *Hint: Use `Node.self()` in the path.*



### Step 4: Testing the Cluster

1. **Start Node 1:** `iex --sname node1 --cookie monster -S mix`
* (We set a cookie "monster" to ensure they match).


2. **Start Node 2:** `iex --sname node2 --cookie monster -S mix`
* *Note:* You might need to set a different HTTP port for Node 2 using environment variables if you did the Web Server chapter (e.g., `PORT=5455`).


3. **Connect:** In Node 2: `Node.connect(:node1@Hostname)`.
4. **Create Data:** In Node 2, create a list for "Bob".
* `Todo.Cache.server_process("Bob")`.
* Add an entry.


5. **Verify Replication:** Check the file system. Do you see "Bob" data in `persist/node1` AND `persist/node2`?
6. **Verify Failover:**
* Kill Node 2 (`System.stop()`).
* In Node 1, ask for "Bob". You should get the process (restarted on Node 1) and the data (loaded from Node 1's disk).



---

### Self-Correction Checklist

* [ ] Did you remove `Todo.ProcessRegistry` from `Todo.System` children?
* [ ] Did you use `:rpc.multicall` for the database store operation?
* [ ] Did you update the database worker to use dynamic paths based on the node name? (e.g., `File.mkdir_p!("#{Node.self()}/persist")`).

---

### Ready for the next step?

Congratulations! You have built a distributed, fault-tolerant, concurrent database system.

The final step is **Chapter 13: Releases**. You cannot ask your customers to install Elixir and type `iex -S mix`. You need to package this as a binary executable.