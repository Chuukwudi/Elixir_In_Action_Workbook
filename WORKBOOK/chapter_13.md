This chapter is the "graduation ceremony." You stop running your code like a developer (`iex -S mix`) and start running it like a sysadmin (as a standalone **Release**). This is how you ship to production.

---

# Chapter 13: Running the System – Releases & Observation

## 1. Chapter Summary

**What is a Release?**

* A **Release** is a self-contained directory containing:
* Your compiled code (`.beam` files).
* All dependencies.
* The **Erlang Runtime (ERTS)** itself.


* **Why?** You can ship this directory to a server that *does not have Elixir or Erlang installed*, and it will just run. It creates a binary executable (e.g., `bin/todo`).

**Building a Release**

* **Command:** `mix release`.
* **Environment:** Usually built with `MIX_ENV=prod`.
* **Configuration:**
* **`mix.exs`:** You can define releases in `project/0` (e.g., `releases: [todo: [...]]`).
* **`vm.args`:** Configures the Erlang VM flags (e.g., `-name`, `-setcookie`).
* **`env.sh`:** Sets environment variables before boot.



**Running a Release**

* **Foreground:** `bin/todo start` (or `start_iex` to get a shell).
* **Daemon (Background):** `bin/todo daemon`.
* **Remote Console:** `bin/todo remote`. This connects a shell to a *running* daemon. This is how you debug live production systems!

**Analyzing Behavior (Observability)**

* **Observer:** You can connect the GUI Observer to a remote production node (via SSH tunneling or shared cookies) to inspect process trees and memory usage live.
* **Tracing (`:sys.trace`):** You can tell a specific process to print every message it receives to the console.
* **Debugging (`:dbg`):** A powerful tool to trace function calls dynamically.

---

## 2. Drills

*These drills focus on the operational commands.*

### Drill 1: The Build Command

**Task:** Write the command to compile your project for **production** and build the release.

**Your Solution:**

```bash
MIX_ENV=prod mix release

```

### Drill 2: Remote Connection

**Task:** You have a release named `my_app` running as a daemon. Write the command to open an IEx shell connected to that live node.

**Your Solution:**

```bash
bin/my_app remote

```

### Drill 3: VM Configuration

**Task:** You want your release to always run with the node name `prod@10.0.0.1` and the cookie `secret`. Which file inside the release folder do you edit?

**Answer:** `releases/0.1.0/vm.args` (or `env.sh` for the name variable).

---

## 3. The Project: Shipping the Todo System

We will package our distributed Todo Cache into a production release.

### Step 1: Prepare `mix.exs`

Open `mix.exs` and ensure your `project` function has the releases configuration (optional in newer Elixir versions, but good practice):

```elixir
def project do
  [
    app: :todo,
    version: "0.1.0",
    # ...
    releases: [
      todo: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  ]
end

```

### Step 2: Build the Release

Run the build command in your terminal:

```bash
mix deps.get
MIX_ENV=prod mix release

```

*Check the output:* It should say `Release created at _build/prod/rel/todo`.

### Step 3: Run Node A (Background)

We will simulate a production node.

```bash
# Set env vars for the port and node name
export RELEASE_NAME=node_a
export RELEASE_NODE=node_a@127.0.0.1
export RELEASE_COOKIE=monster
export TODO_PORT=5001

# Start as daemon
_build/prod/rel/todo/bin/todo daemon

```

### Step 4: Run Node B (Interactive)

We will run a second node in the foreground to talk to Node A.

```bash
# New terminal
export RELEASE_NAME=node_b
export RELEASE_NODE=node_b@127.0.0.1
export RELEASE_COOKIE=monster
export TODO_PORT=5002

# Start interactive
_build/prod/rel/todo/bin/todo start_iex

```

### Step 5: Connect and Verify

Inside the **Node B** shell:

1. Connect: `Node.connect(:"node_a@127.0.0.1")`.
2. Store Data:
```elixir
# This uses the global registry to find the process, which might be on Node A or B
pid = Todo.Cache.server_process("production_list")
Todo.Server.add_entry(pid, %{date: ~D[2023-01-01], title: "Deploy Successful"})

```


3. Exit Node B.

### Step 6: Remote Inspection

Now, let's debug **Node A** (which is still running in the background) without stopping it.

```bash
# Connect a remote shell to Node A
RELEASE_NODE=node_a@127.0.0.1 RELEASE_COOKIE=monster _build/prod/rel/todo/bin/todo remote

```

* **Verify:** Inside this remote shell, check `Todo.Server.entries(pid, ...)` or use `:observer.start()` (if your local machine supports UI forwarding) to see the supervision tree.

### Step 7: Shutdown

Exit the remote shell. Stop Node A:

```bash
_build/prod/rel/todo/bin/todo stop

```

---

### Self-Correction Checklist

* [ ] Did the release build successfully?
* [ ] Did you set the `RELEASE_COOKIE` to be the same for both nodes? (They won't connect otherwise).
* [ ] Did you use `bin/todo remote` to connect to the daemon?

---

# Congratulations! You have Mastered Elixir.

You have journeyed from basic functional syntax to building a fault-tolerant, distributed, database-backed, HTTP-serving, production-ready system.

**Your Journey Recap:**

1. **Ch 1-4:** Functional Core (Modules, Functions, Structs, Maps).
2. **Ch 5-7:** Concurrency (Processes, GenServer, System Architecture).
3. **Ch 8-9:** Reliability (Supervisors, Fault Tolerance, Isolation).
4. **Ch 10:** Tooling (Tasks, Agents, ETS).
5. **Ch 11-13:** Engineering (Applications, Web Servers, Distribution, Releases).

**Where to go from here?**

* **Phoenix Framework:** You are now perfectly equipped to learn Phoenix. You understand Plug, Cowboy, and Concurrency—Phoenix is just a supervision tree of these components!
* **Nerves:** If you want to run Elixir on embedded hardware (Raspberry Pi), Nerves builds on the "Release" concept you just learned.
* **Broadway:** For high-volume data processing pipelines.

Thank you for working through *Elixir in Action* with me. It has been a pleasure being your guide!