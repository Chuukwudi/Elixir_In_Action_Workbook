# Chapter 13: Running the System - Learning Exercises

## Chapter Summary

Chapter 13 focuses on production deployment and operations, covering how to run BEAM systems using Elixir tools (mix, elixir commands, scripts) for development and testing, and OTP releases for production deployments. Releases provide standalone, self-contained packages with minimal runtime requirements, embedding the Erlang runtime and all dependencies without source code. The chapter explores building releases with `mix release`, configuring runtime behavior, connecting to running systems via remote shells, and using powerful introspection tools like `:observer`, `:sys`, and `:erlang` module functions to monitor, debug, and analyze production systems in real-time without disrupting service.

---

## Concept Drills

### Drill 1: Running with Mix and Elixir

**Objective:** Understand different ways to start a system.

**Task:** Explore various startup commands:

```bash
# Interactive shell (development)
$ iex -S mix

# Run without shell
$ mix run --no-halt

# Run with elixir command
$ elixir -S mix run --no-halt

# Detached mode (background)
$ elixir --erl "-detached" --sname my_app@localhost -S mix run --no-halt

# Check running nodes
$ epmd -names
epmd: up and running on port 4369 with data:
name my_app at port 51028
```

**Exercises:**
1. Start your application in each mode
2. What's the difference between `mix run` and `iex -S mix`?
3. Start a detached node - how do you verify it's running?
4. Connect to the detached node with `--remsh`
5. Stop it gracefully with `System.stop/0`

**Remote Shell:**
```bash
$ iex --sname debugger@localhost --remsh my_app@localhost --hidden
iex(my_app@localhost)1> System.stop()
```

---

### Drill 2: Mix Environments

**Objective:** Use dev, test, and prod environments effectively.

**Task:** Understand compile-time environment branches:

```elixir
defmodule MyApp.Config do
  @compile_env Mix.env()

  def environment, do: @compile_env

  case Mix.env() do
    :dev ->
      def log_level, do: :debug
      def pool_size, do: 5

    :test ->
      def log_level, do: :warn
      def pool_size, do: 1

    :prod ->
      def log_level, do: :error
      def pool_size, do: 20
  end

  def settings do
    %{
      env: environment(),
      log_level: log_level(),
      pool_size: pool_size()
    }
  end
end
```

**Test Different Environments:**
```bash
# Development (default)
$ iex -S mix
iex> MyApp.Config.settings()
# => %{env: :dev, log_level: :debug, pool_size: 5}

# Test
$ MIX_ENV=test iex -S mix
iex> MyApp.Config.settings()
# => %{env: :test, log_level: :warn, pool_size: 1}

# Production
$ MIX_ENV=prod iex -S mix
iex> MyApp.Config.settings()
# => %{env: :prod, log_level: :error, pool_size: 20}
```

**Important Notes:**
- `Mix.env/0` works only at compile time
- Changing `MIX_ENV` requires recompilation
- Use Application env for runtime config
- Compiled files go to `_build/<env>/`

---

### Drill 3: Elixir Scripts

**Objective:** Create standalone scripts with Mix.install.

**Task:** Build a data processing script:

```elixir
# process_csv.exs
Mix.install([
  {:csv, "~> 3.0"},
  {:jason, "~> 1.4"}
])

defmodule CSVProcessor do
  def run(file_path) do
    file_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(&process_row/1)
    |> summarize()
    |> Jason.encode!(pretty: true)
    |> IO.puts()
  end

  defp process_row(row) do
    %{
      name: row["name"],
      value: String.to_integer(row["value"]),
      category: row["category"]
    }
  end

  defp summarize(rows) do
    rows
    |> Enum.group_by(& &1.category)
    |> Enum.map(fn {category, items} ->
      {category, %{
        count: length(items),
        total: Enum.sum(Enum.map(items, & &1.value))
      }}
    end)
    |> Map.new()
  end
end

[file_path] = System.argv()
CSVProcessor.run(file_path)
```

**Run the script:**
```bash
$ elixir process_csv.exs data.csv
{
  "electronics": {
    "count": 5,
    "total": 1250
  },
  "books": {
    "count": 3,
    "total": 75
  }
}
```

**Exercises:**
1. Create a JSON validator script
2. Add command-line argument parsing
3. Handle errors gracefully
4. Add progress reporting
5. What are the trade-offs vs full Mix project?

---

### Drill 4: Building OTP Releases

**Objective:** Create a standalone release package.

**Task:** Build and run a release:

```bash
# Compile for production
$ MIX_ENV=prod mix compile

# Build the release
$ MIX_ENV=prod mix release

* assembling my_app-0.1.0 on MIX_ENV=prod
* using config/runtime.exs to configure the release at runtime

Release created at _build/prod/rel/my_app

    # To start your system
    _build/prod/rel/my_app/bin/my_app start

# Run the release
$ _build/prod/rel/my_app/bin/my_app start

# Check if running
$ _build/prod/rel/my_app/bin/my_app pid
12345

# Stop the release
$ _build/prod/rel/my_app/bin/my_app stop
```

**Release Structure:**
```
_build/prod/rel/my_app/
├── bin/
│   └── my_app           # Start script
├── erts-<version>/      # Erlang runtime
├── lib/
│   ├── my_app-0.1.0/   # Your app
│   ├── stdlib-<ver>/    # Erlang stdlib
│   └── ...              # Dependencies
└── releases/
    └── 0.1.0/
        ├── start.boot
        ├── sys.config
        └── vm.args
```

**Exercises:**
1. Build a release for your project
2. Examine the directory structure
3. Start and stop the release
4. What's included vs excluded?
5. How large is the release?

---

### Drill 5: Release Configuration

**Objective:** Configure releases for different environments.

**Task:** Set up runtime configuration:

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is not set"

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  port =
    System.get_env("PORT") ||
      raise "PORT environment variable is not set"

  config :my_app,
    port: String.to_integer(port)

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is not set"

  config :my_app, MyAppWeb.Endpoint,
    secret_key_base: secret_key_base
end
```

**Using Environment Variables:**
```bash
# Export variables
$ export DATABASE_URL=postgres://localhost/myapp_prod
$ export PORT=4000
$ export SECRET_KEY_BASE=very_secret_key_base_string

# Start release
$ _build/prod/rel/my_app/bin/my_app start

# Or inline
$ DATABASE_URL=postgres://... PORT=4000 _build/prod/rel/my_app/bin/my_app start
```

**Release Configuration File (rel/env.sh.eex):**
```bash
#!/bin/sh

# Custom environment setup
export RELEASE_NODE=my_app@${HOSTNAME}
export RELEASE_COOKIE=my_secret_cookie
export RELEASE_TMP=/tmp
```

---

### Drill 6: Remote Console and Debugging

**Objective:** Connect to and debug running releases.

**Task:** Use remote console for live debugging:

```bash
# Start release
$ _build/prod/rel/my_app/bin/my_app start

# Connect with remote console
$ _build/prod/rel/my_app/bin/my_app remote
iex(my_app@hostname)1>
```

**Useful Commands:**
```elixir
# List all applications
Application.started_applications()

# Get application environment
Application.get_all_env(:my_app)

# List all processes
Process.list() |> length()

# Find a process
Process.whereis(:my_gen_server)

# Get process info
pid = Process.whereis(:my_gen_server)
Process.info(pid)

# System info
:erlang.memory()
:erlang.system_info(:process_count)
:erlang.system_info(:schedulers_online)

# Application state
:sys.get_state(MyApp.Server)

# Hot code reload (be careful!)
:code.load_file(MyApp.UpdatedModule)
```

**RPC to Release:**
```bash
# Execute code on running release
$ _build/prod/rel/my_app/bin/my_app rpc "IO.puts('Hello from release')"

# Evaluate expression
$ _build/prod/rel/my_app/bin/my_app eval ":erlang.memory(:total)"
```

---

### Drill 7: Observer and System Introspection

**Objective:** Use Observer for live system monitoring.

**Task:** Start and use Observer:

```elixir
# In iex
iex> :observer.start()
```

**Observer Features:**
- **System Tab** - CPU, memory, ports, ETS tables
- **Load Charts** - Real-time graphs
- **Applications** - Supervision tree visualization
- **Processes** - All running processes, sorting, filtering
- **Table Viewer** - Inspect ETS and Mnesia tables
- **Trace** - Message and function call tracing

**Programmatic Inspection:**
```elixir
# Top processes by memory
Process.list()
|> Enum.map(fn pid ->
  {pid, Process.info(pid, :memory)}
end)
|> Enum.sort_by(fn {_pid, {:memory, bytes}} -> -bytes end)
|> Enum.take(10)

# Process information
pid = self()
Process.info(pid, [:memory, :message_queue_len, :reductions, :status])

# Trace messages
:sys.trace(MyApp.Server, true)
GenServer.call(MyApp.Server, :some_request)
:sys.trace(MyApp.Server, false)

# Get state
:sys.get_state(MyApp.Server)
```

---

## Integration Exercises

### Exercise 1: Production-Ready Configuration

**Objective:** Set up complete environment-specific configuration.

**Concepts Reinforced:**
- Mix environments (Chapter 13)
- Runtime configuration (Chapter 13)
- Application behavior (Chapter 11)

**Task:**

```elixir
# config/config.exs
import Config

config :my_app,
  ecto_repos: [MyApp.Repo]

# Common configuration
config :my_app, MyApp.Repo,
  migration_timestamps: [type: :utc_datetime]

import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :logger, level: :debug
```

```elixir
# config/test.exs
import Config

config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :logger, level: :warning
```

```elixir
# config/prod.exs
import Config

config :logger, level: :info
```

```elixir
# config/runtime.exs
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  port = String.to_integer(System.get_env("PORT") || "4000")

  config :my_app, MyAppWeb.Endpoint,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
end
```

---

### Exercise 2: Release with Migrations

**Objective:** Build a release that can run database migrations.

**Concepts Reinforced:**
- Releases (Chapter 13)
- Task modules (Chapter 10)
- Application lifecycle (Chapter 11)

**Task:**

```elixir
# lib/my_app/release.ex
defmodule MyApp.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :my_app

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
```

**Add to mix.exs:**
```elixir
def project do
  [
    # ...
    releases: [
      my_app: [
        steps: [:assemble, :tar]
      ]
    ]
  ]
end
```

**Run migrations:**
```bash
# In release
$ _build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate()"

# Or via custom command
$ _build/prod/rel/my_app/bin/my_app rpc "MyApp.Release.migrate()"
```

---

### Exercise 3: Health Check Endpoint

**Objective:** Add health monitoring to running systems.

**Concepts Reinforced:**
- Releases (Chapter 13)
- GenServer (Chapter 6)
- Remote calls (Chapter 12)

**Task:**

```elixir
defmodule MyApp.HealthCheck do
  def status do
    %{
      status: :healthy,
      timestamp: DateTime.utc_now(),
      node: node(),
      system: system_metrics(),
      applications: application_status(),
      database: database_status()
    }
  end

  defp system_metrics do
    %{
      memory: :erlang.memory(:total),
      processes: :erlang.system_info(:process_count),
      run_queue: :erlang.statistics(:run_queue),
      uptime: :erlang.statistics(:wall_clock) |> elem(0)
    }
  end

  defp application_status do
    Application.started_applications()
    |> Enum.map(fn {app, _desc, _vsn} ->
      {app, :running}
    end)
    |> Map.new()
  end

  defp database_status do
    try do
      case MyApp.Repo.query("SELECT 1") do
        {:ok, _} -> :connected
        {:error, _} -> :error
      end
    catch
      _, _ -> :error
    end
  end
end
```

**HTTP Endpoint:**
```elixir
defmodule MyAppWeb.HealthController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    status = MyApp.HealthCheck.status()

    conn
    |> put_status(if status.status == :healthy, do: 200, else: 503)
    |> json(status)
  end
end
```

**Check from shell:**
```bash
$ curl http://localhost:4000/health
```

---

### Exercise 4: Deployment Script

**Objective:** Automate release deployment.

**Concepts Reinforced:**
- Releases (Chapter 13)
- Shell scripting
- Remote operations (Chapter 12)

**Task:**

```bash
#!/bin/bash
# deploy.sh

set -e

APP_NAME="my_app"
BUILD_HOST="builder@build-server"
DEPLOY_HOST="deploy@prod-server"
DEPLOY_PATH="/opt/$APP_NAME"

echo "==> Building release..."
ssh $BUILD_HOST << 'ENDSSH'
cd /builds/my_app
git pull origin main
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix release --overwrite
ENDSSH

echo "==> Downloading release..."
scp $BUILD_HOST:/builds/my_app/_build/prod/$APP_NAME-*.tar.gz /tmp/

echo "==> Uploading to production..."
scp /tmp/$APP_NAME-*.tar.gz $DEPLOY_HOST:$DEPLOY_PATH/

echo "==> Stopping old release..."
ssh $DEPLOY_HOST "$DEPLOY_PATH/bin/$APP_NAME stop || true"

echo "==> Extracting new release..."
ssh $DEPLOY_HOST << ENDSSH
cd $DEPLOY_PATH
tar -xzf $APP_NAME-*.tar.gz
rm $APP_NAME-*.tar.gz
ENDSSH

echo "==> Starting new release..."
ssh $DEPLOY_HOST "$DEPLOY_PATH/bin/$APP_NAME daemon"

echo "==> Waiting for startup..."
sleep 5

echo "==> Running migrations..."
ssh $DEPLOY_HOST "$DEPLOY_PATH/bin/$APP_NAME rpc 'MyApp.Release.migrate()'"

echo "==> Deployment complete!"
```

---

## Capstone Project: Production Monitoring Dashboard

### Project Description

Build a comprehensive monitoring and debugging system for production BEAM applications that provides real-time insights, health checks, metrics collection, and interactive debugging capabilities accessible via web interface.

### Architecture

```
Monitor.System
├── Monitor.Application
│   ├── Monitor.Collector (metrics gathering)
│   ├── Monitor.Storage (time-series data)
│   ├── Monitor.Alerts (threshold monitoring)
│   ├── Monitor.WebSocket (real-time updates)
│   └── MonitorWeb.Endpoint (Phoenix web UI)
```

### Requirements

#### 1. Metrics Collector

```elixir
defmodule Monitor.Collector do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get_snapshot do
    GenServer.call(__MODULE__, :snapshot)
  end

  @impl GenServer
  def init(_) do
    schedule_collection()
    {:ok, %{history: []}}
  end

  @impl GenServer
  def handle_info(:collect, state) do
    metrics = collect_metrics()
    Monitor.Storage.store(metrics)

    new_history = [metrics | Enum.take(state.history, 99)]

    schedule_collection()
    {:noreply, %{state | history: new_history}}
  end

  @impl GenServer
  def handle_call(:snapshot, _from, state) do
    {:reply, List.first(state.history), state}
  end

  defp collect_metrics do
    %{
      timestamp: System.system_time(:second),
      node: node(),
      system: %{
        memory: :erlang.memory(),
        process_count: :erlang.system_info(:process_count),
        port_count: :erlang.system_info(:port_count),
        run_queue: :erlang.statistics(:run_queue),
        schedulers: :erlang.system_info(:schedulers_online),
        uptime: :erlang.statistics(:wall_clock) |> elem(0)
      },
      applications: collect_application_metrics(),
      processes: collect_process_metrics(),
      ets: collect_ets_metrics()
    }
  end

  defp collect_application_metrics do
    Application.started_applications()
    |> Enum.map(fn {app, _desc, vsn} ->
      {app, %{version: to_string(vsn), status: :running}}
    end)
    |> Map.new()
  end

  defp collect_process_metrics do
    processes = Process.list()

    %{
      total: length(processes),
      top_memory: top_processes_by(:memory, 10),
      top_reductions: top_processes_by(:reductions, 10),
      message_queues: processes_with_messages()
    }
  end

  defp collect_ets_metrics do
    :ets.all()
    |> Enum.map(fn table ->
      info = :ets.info(table)
      %{
        name: info[:name],
        size: info[:size],
        memory: info[:memory],
        type: info[:type]
      }
    end)
  end

  defp top_processes_by(key, limit) do
    Process.list()
    |> Enum.map(fn pid ->
      info = Process.info(pid, [key, :registered_name, :initial_call])
      {pid, info}
    end)
    |> Enum.sort_by(fn {_, info} -> -(info[key] || 0) end)
    |> Enum.take(limit)
    |> Enum.map(fn {pid, info} ->
      %{
        pid: inspect(pid),
        registered_name: info[:registered_name],
        initial_call: info[:initial_call],
        value: info[key]
      }
    end)
  end

  defp processes_with_messages do
    Process.list()
    |> Enum.map(fn pid ->
      {:message_queue_len, len} = Process.info(pid, :message_queue_len)
      {pid, len}
    end)
    |> Enum.filter(fn {_pid, len} -> len > 0 end)
    |> Enum.sort_by(fn {_pid, len} -> -len end)
    |> Enum.take(10)
    |> Enum.map(fn {pid, len} ->
      %{pid: inspect(pid), queue_length: len}
    end)
  end

  defp schedule_collection do
    Process.send_after(self(), :collect, 5_000)
  end
end
```

#### 2. Alert System

```elixir
defmodule Monitor.Alerts do
  use GenServer

  @thresholds %{
    memory_percent: 90,
    process_count: 100_000,
    message_queue_len: 10_000
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def check_metrics(metrics) do
    GenServer.cast(__MODULE__, {:check, metrics})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{alerts: [], alert_history: []}}
  end

  @impl GenServer
  def handle_cast({:check, metrics}, state) do
    alerts = [
      check_memory(metrics),
      check_process_count(metrics),
      check_message_queues(metrics)
    ]
    |> Enum.reject(&is_nil/1)

    new_state = if alerts != [] do
      notify_alerts(alerts)
      %{state |
        alerts: alerts,
        alert_history: [%{timestamp: System.system_time(), alerts: alerts} | Enum.take(state.alert_history, 99)]
      }
    else
      %{state | alerts: []}
    end

    {:noreply, new_state}
  end

  defp check_memory(metrics) do
    total = metrics.system.memory[:total]
    used_percent = (total / (1024 * 1024 * 1024)) * 100  # rough calculation

    if used_percent > @thresholds.memory_percent do
      %{
        severity: :warning,
        type: :high_memory,
        message: "Memory usage at #{Float.round(used_percent, 2)}%",
        value: total
      }
    end
  end

  defp check_process_count(metrics) do
    count = metrics.system.process_count

    if count > @thresholds.process_count do
      %{
        severity: :critical,
        type: :high_process_count,
        message: "Process count: #{count}",
        value: count
      }
    end
  end

  defp check_message_queues(metrics) do
    max_queue = metrics.processes.message_queues
    |> Enum.map(& &1.queue_length)
    |> Enum.max(fn -> 0 end)

    if max_queue > @thresholds.message_queue_len do
      %{
        severity: :warning,
        type: :long_message_queue,
        message: "Process has #{max_queue} messages in queue",
        value: max_queue
      }
    end
  end

  defp notify_alerts(alerts) do
    # Send notifications (email, Slack, PagerDuty, etc.)
    Enum.each(alerts, fn alert ->
      IO.warn("ALERT: #{alert.message}")
    end)
  end
end
```

#### 3. Web Interface

```elixir
defmodule MonitorWeb.DashboardLive do
  use MonitorWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1_000, self(), :update)
    end

    {:ok, assign(socket, metrics: Monitor.Collector.get_snapshot())}
  end

  @impl Phoenix.LiveView
  def handle_info(:update, socket) do
    metrics = Monitor.Collector.get_snapshot()
    {:noreply, assign(socket, metrics: metrics)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="dashboard">
      <h1>System Monitor</h1>

      <div class="metrics-grid">
        <div class="metric-card">
          <h3>Memory</h3>
          <p class="metric-value">
            <%= format_bytes(@metrics.system.memory[:total]) %>
          </p>
        </div>

        <div class="metric-card">
          <h3>Processes</h3>
          <p class="metric-value">
            <%= @metrics.system.process_count %>
          </p>
        </div>

        <div class="metric-card">
          <h3>Run Queue</h3>
          <p class="metric-value">
            <%= @metrics.system.run_queue %>
          </p>
        </div>

        <div class="metric-card">
          <h3>Uptime</h3>
          <p class="metric-value">
            <%= format_uptime(@metrics.system.uptime) %>
          </p>
        </div>
      </div>

      <div class="section">
        <h2>Top Processes by Memory</h2>
        <table>
          <thead>
            <tr>
              <th>PID</th>
              <th>Name</th>
              <th>Memory</th>
            </tr>
          </thead>
          <tbody>
            <%= for proc <- @metrics.processes.top_memory do %>
              <tr>
                <td><%= proc.pid %></td>
                <td><%= inspect(proc.registered_name || proc.initial_call) %></td>
                <td><%= format_bytes(proc.value) %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp format_bytes(bytes) do
    cond do
      bytes > 1_000_000_000 -> "#{Float.round(bytes / 1_000_000_000, 2)} GB"
      bytes > 1_000_000 -> "#{Float.round(bytes / 1_000_000, 2)} MB"
      bytes > 1_000 -> "#{Float.round(bytes / 1_000, 2)} KB"
      true -> "#{bytes} B"
    end
  end

  defp format_uptime(ms) do
    seconds = div(ms, 1_000)
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)

    "#{days}d #{rem(hours, 24)}h #{rem(minutes, 60)}m"
  end
end
```

### Bonus Features

1. **Process Inspector** - Click to inspect any process
2. **Message Tracing** - Real-time message flow visualization
3. **Code Hot-Swap** - Upload new modules without restart
4. **Multi-Node Dashboard** - Monitor entire cluster
5. **Historical Charts** - Time-series graphs with Chart.js
6. **Custom Queries** - REPL for remote code execution

### Evaluation Criteria

**Release Management (25 points)**
- Proper release configuration (10 pts)
- Runtime configuration (10 pts)
- Deployment automation (5 pts)

**Monitoring (30 points)**
- Metrics collection (10 pts)
- Real-time updates (10 pts)
- Alert system (10 pts)

**Debugging Tools (25 points)**
- Process inspection (10 pts)
- System introspection (10 pts)
- Remote capabilities (5 pts)

**Production Readiness (20 points)**
- Health checks (10 pts)
- Error handling (5 pts)
- Documentation (5 pts)

---

## Success Checklist

Congratulations! You've completed the full Elixir in Action curriculum. Ensure you can:

- [ ] Run systems with mix and elixir commands
- [ ] Use Mix environments effectively
- [ ] Create standalone Elixir scripts
- [ ] Build OTP releases
- [ ] Configure releases for production
- [ ] Use runtime configuration
- [ ] Connect to running releases
- [ ] Execute remote commands
- [ ] Use Observer for monitoring
- [ ] Inspect processes and state
- [ ] Use :sys for tracing
- [ ] Collect system metrics
- [ ] Build health check endpoints
- [ ] Deploy releases safely
- [ ] Debug production systems

---

## Final Thoughts

You've now mastered the complete journey from Elixir basics through production deployment:

**Foundations (Ch 1-4):** Language fundamentals, functional programming, data abstractions

**Concurrency (Ch 5-6):** Processes, message passing, stateful servers with GenServer

**Fault Tolerance (Ch 7-9):** OTP behaviors, supervision trees, error isolation

**Advanced Patterns (Ch 10):** Tasks, Agents, ETS for performance

**Production (Ch 11-13):** Applications, distribution, releases, monitoring

### Next Steps

1. **Build Real Projects** - Apply these concepts to production systems
2. **Explore Phoenix** - Web framework built on these foundations
3. **Study Nerves** - Embedded systems with Elixir
4. **Contribute to Open Source** - Read and contribute to Elixir libraries
5. **Master Operations** - Kubernetes, Docker, distributed tracing
6. **Keep Learning** - The BEAM ecosystem is vast and evolving

### Recommended Resources

- **Elixir Documentation** - https://hexdocs.pm/elixir
- **Erlang Documentation** - https://www.erlang.org/docs
- **Elixir Forum** - https://elixirforum.com
- **Awesome Elixir** - https://github.com/h4cc/awesome-elixir
- **Phoenix Framework** - https://phoenixframework.org

**Happy Coding! 🚀**
