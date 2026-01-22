# Chapter 11: Working with Components - Learning Exercises

## Chapter Summary

Chapter 11 focuses on OTP applications, the standard way of packaging Elixir/Erlang systems into reusable components with managed dependencies and deployable releases. An OTP application consists of modules, an application resource file, dependency specifications, and an optional application callback module that starts the supervision tree, enabling entire systems to start with a single command. The chapter demonstrates converting projects into proper OTP applications, managing dependencies through Mix and Hex, working with third-party libraries (including Erlang libraries like Poolboy), and building production-ready web servers using Plug and Cowboy while understanding application configuration and environment management.

---

## Concept Drills

### Drill 1: Creating an OTP Application

**Objective:** Understand the structure and components of an OTP application.

**Task:** Create a minimal OTP application:

```bash
mix new counter_app --sup
cd counter_app
```

**Examine the generated files:**

```elixir
# mix.exs
defmodule CounterApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :counter_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {CounterApp.Application, []}
    ]
  end

  defp deps do
    []
  end
end
```

```elixir
# lib/counter_app/application.ex
defmodule CounterApp.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Add workers here
    ]

    opts = [strategy: :one_for_one, name: CounterApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Exercises:**
1. Start the application with `iex -S mix`
2. Check running applications: `Application.started_applications/0`
3. Stop the application: `Application.stop(:counter_app)`
4. Restart it: `Application.ensure_all_started(:counter_app)`
5. What happens when you try to start it twice?

**Key Components:**
- `app:` - Application name (atom)
- `version:` - Semantic version
- `start_permanent:` - Restart strategy in prod
- `deps:` - Third-party dependencies
- `mod:` - Application callback module

---

### Drill 2: Application Callback Module

**Objective:** Implement the Application behavior correctly.

**Task:** Add a supervised worker to your application:

```elixir
defmodule CounterApp.Counter do
  use GenServer

  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def increment do
    GenServer.cast(__MODULE__, :increment)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  @impl GenServer
  def init(initial_value) do
    {:ok, initial_value}
  end

  @impl GenServer
  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end
end
```

**Update Application:**
```elixir
defmodule CounterApp.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {CounterApp.Counter, 0}
    ]

    opts = [strategy: :one_for_one, name: CounterApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Test:**
```elixir
iex -S mix
iex> CounterApp.Counter.increment()
iex> CounterApp.Counter.get()
# => 1
```

**Questions:**
1. What are the arguments to `start/2`?
2. What should `start/2` return?
3. What happens if `start/2` returns an error?
4. Can you start multiple instances of the same application?

---

### Drill 3: Library Applications

**Objective:** Understand applications without supervision trees.

**Task:** Create a utility library application:

```elixir
# mix.exs for a library
defmodule MathUtils.MixProject do
  use Mix.Project

  def project do
    [
      app: :math_utils,
      version: "1.0.0",
      elixir: "~> 1.15"
    ]
  end

  def application do
    # No mod: specified - library application
    [
      extra_applications: [:logger]
    ]
  end
end
```

```elixir
# lib/math_utils.ex
defmodule MathUtils do
  def factorial(0), do: 1
  def factorial(n) when n > 0, do: n * factorial(n - 1)

  def gcd(a, 0), do: abs(a)
  def gcd(a, b), do: gcd(b, rem(a, b))

  def lcm(a, b), do: div(abs(a * b), gcd(a, b))
end
```

**Exercises:**
1. Start this application - what happens?
2. Does it have a supervision tree?
3. When would you use a library application?
4. Can library applications have dependencies?

**Use Cases for Library Applications:**
- Utility functions (JSON parsers, CSV parsers)
- Pure computations
- Protocols and behaviours
- No need for long-running processes

---

### Drill 4: Managing Dependencies

**Objective:** Add and manage third-party dependencies.

**Task:** Add dependencies to a project:

```elixir
defp deps do
  [
    {:jason, "~> 1.4"},              # JSON parser
    {:plug_cowboy, "~> 2.6"},        # Web server
    {:httpoison, "~> 2.0"},          # HTTP client
    {:timex, "~> 3.7"}               # Date/time utilities
  ]
end
```

**Fetch dependencies:**
```bash
mix deps.get
```

**Exercises:**
1. Run `mix deps.get` and observe what gets downloaded
2. Check `mix.lock` - what does it contain?
3. Run `mix deps.tree` to see dependency hierarchy
4. Run `mix deps.update jason` to update one dependency
5. Run `mix deps.clean --all` then `mix deps.get`

**Version Requirements:**
```elixir
{:package, "~> 1.2"}      # >= 1.2.0 and < 2.0.0
{:package, "~> 1.2.3"}    # >= 1.2.3 and < 1.3.0
{:package, ">= 1.0.0"}    # Any version >= 1.0.0
{:package, "1.2.3"}       # Exactly 1.2.3
```

**Other Dependency Sources:**
```elixir
# GitHub
{:package, github: "user/repo"}

# Git
{:package, git: "https://github.com/user/repo.git", tag: "v1.0"}

# Local path
{:package, path: "../package"}
```

---

### Drill 5: Mix Environments

**Objective:** Understand dev, test, and prod environments.

**Task:** Configure different behaviors per environment:

```elixir
# config/config.exs
import Config

config :my_app,
  log_level: :info,
  database: "my_app_dev"

# Import environment-specific config
import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :my_app,
  log_level: :debug,
  database: "my_app_dev"
```

```elixir
# config/test.exs
import Config

config :my_app,
  log_level: :warn,
  database: "my_app_test"
```

```elixir
# config/prod.exs
import Config

config :my_app,
  log_level: :error,
  database: "my_app_prod"
```

**Access configuration:**
```elixir
defmodule MyApp do
  def database_name do
    Application.get_env(:my_app, :database)
  end

  def log_level do
    Application.get_env(:my_app, :log_level)
  end
end
```

**Test different environments:**
```bash
# Default (dev)
iex -S mix

# Test
MIX_ENV=test iex -S mix

# Production
MIX_ENV=prod iex -S mix
```

**Exercises:**
1. Print config in each environment
2. When does mix use test environment by default?
3. Where are compiled files for each environment?
4. Why is prod environment important locally?

---

### Drill 6: Application Structure

**Objective:** Understand compiled application folder structure.

**Task:** Explore the `_build` directory:

```bash
# Compile for different environments
mix compile
MIX_ENV=test mix compile
MIX_ENV=prod mix compile

# Examine structure
tree _build/dev/lib/my_app
```

**Structure:**
```
_build/
├── dev/
│   └── lib/
│       ├── my_app/
│       │   ├── ebin/           # Compiled .beam files
│       │   │   ├── my_app.app  # Application resource file
│       │   │   └── *.beam
│       │   └── priv/           # Static assets
│       └── dependency1/
├── test/
│   └── lib/
└── prod/
    └── lib/
```

**Examine .app file:**
```bash
cat _build/dev/lib/my_app/ebin/my_app.app
```

**Example content:**
```erlang
{application,my_app,
             [{applications,[kernel,stdlib,elixir,logger]},
              {description,"my_app"},
              {modules,['Elixir.MyApp','Elixir.MyApp.Application']},
              {registered,[]},
              {vsn,"0.1.0"},
              {mod,{'Elixir.MyApp.Application',[]}}]}.
```

**Questions:**
1. What's in the ebin folder?
2. What's the priv folder for?
3. Why separate folders per environment?
4. What is the .app file?

---

### Drill 7: Extra Applications

**Objective:** Understand `extra_applications` in mix.exs.

**Task:** Specify runtime application dependencies:

```elixir
def application do
  [
    extra_applications: [:logger, :crypto, :ssl, :inets],
    mod: {MyApp.Application, []}
  ]
end
```

**Common Extra Applications:**
- `:logger` - Logging facilities
- `:crypto` - Cryptographic functions
- `:ssl` - SSL/TLS support
- `:inets` - HTTP client/server
- `:sasl` - System architecture support libraries
- `:os_mon` - OS monitoring
- `:runtime_tools` - Runtime tracing/debugging

**Use in Code:**
```elixir
# These work because :crypto is in extra_applications
:crypto.strong_rand_bytes(32)
:crypto.hash(:sha256, "data")
```

**Exercises:**
1. Add `:crypto` to extra_applications
2. Use `:crypto.strong_rand_bytes(16)` in your code
3. Remove it from extra_applications - what happens?
4. Why not all Erlang/Elixir apps need to be listed?

---

## Integration Exercises

### Exercise 1: Convert Existing Project to OTP App

**Objective:** Turn a collection of modules into a proper OTP application.

**Concepts Reinforced:**
- OTP applications (Chapter 11)
- Supervision trees (Chapter 9)
- GenServer (Chapter 6)

**Task:** You have these modules, convert them to an OTP app:

```elixir
# Before: Manual setup required
defmodule Cache do
  use GenServer
  # ... implementation
end

defmodule Database do
  use GenServer
  # ... implementation
end

defmodule API do
  # Uses Cache and Database
end
```

**Convert to:**

```elixir
# mix.exs
defmodule MySystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_system,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MySystem.Application, []}
    ]
  end
end
```

```elixir
# lib/my_system/application.ex
defmodule MySystem.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: MySystem.Registry},
      MySystem.Database,
      MySystem.Cache,
      MySystem.API
    ]

    opts = [strategy: :one_for_one, name: MySystem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Requirements:**
1. Proper supervision tree
2. Automatic startup with `iex -S mix`
3. Tests work without manual setup
4. Clean shutdown with `Application.stop/1`

**Success Criteria:**
- Application starts all components automatically
- Components can find each other via Registry
- Tests pass without manual process starting
- `mix test` works out of the box

---

### Exercise 2: Multi-Environment Configuration

**Objective:** Configure application for different environments.

**Concepts Reinforced:**
- Application configuration (Chapter 11)
- Mix environments (Chapter 11)
- Runtime configuration (Chapter 11)

**Task:** Build a database-backed application with environment-specific config:

```elixir
# config/config.exs
import Config

config :my_db_app,
  ecto_repos: [MyDbApp.Repo]

config :my_db_app, MyDbApp.Repo,
  database: "my_db_app_dev",
  hostname: "localhost",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :my_db_app, MyDbApp.Repo,
  database: "my_db_app_dev",
  pool_size: 10,
  show_sensitive_data_on_connection_error: true,
  log: :debug
```

```elixir
# config/test.exs
import Config

config :my_db_app, MyDbApp.Repo,
  database: "my_db_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  log: false
```

```elixir
# config/prod.exs
import Config

config :my_db_app, MyDbApp.Repo,
  pool_size: 20,
  log: :warn
```

```elixir
# config/runtime.exs - For runtime configuration
import Config

if config_env() == :prod do
  database_url = System.get_env("DATABASE_URL") ||
    raise "DATABASE_URL not set"

  config :my_db_app, MyDbApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
```

**Implementation:**
```elixir
defmodule MyDbApp.Config do
  def database_name do
    :my_db_app
    |> Application.get_env(MyDbApp.Repo)
    |> Keyword.get(:database)
  end

  def pool_size do
    :my_db_app
    |> Application.get_env(MyDbApp.Repo)
    |> Keyword.get(:pool_size)
  end
end
```

**Test:**
```bash
# Development
iex -S mix
iex> MyDbApp.Config.database_name()
# => "my_db_app_dev"

# Test
MIX_ENV=test iex -S mix
iex> MyDbApp.Config.database_name()
# => "my_db_app_test"

# Production with env vars
DATABASE_URL=postgres://... POOL_SIZE=20 MIX_ENV=prod iex -S mix
```

**Requirements:**
1. Different database per environment
2. Different pool sizes
3. Production uses environment variables
4. Sensitive data handling per environment

---

### Exercise 3: Dependency Integration

**Objective:** Integrate third-party libraries into an application.

**Concepts Reinforced:**
- Dependencies (Chapter 11)
- Supervision (Chapter 9)
- GenServer (Chapter 6)

**Task:** Build an HTTP API client with caching:

```elixir
# mix.exs
defp deps do
  [
    {:httpoison, "~> 2.0"},
    {:jason, "~> 1.4"},
    {:cachex, "~> 3.6"}
  ]
end

def application do
  [
    extra_applications: [:logger],
    mod: {APIClient.Application, []}
  ]
end
```

```elixir
# lib/api_client/application.ex
defmodule APIClient.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Cachex, name: :api_cache}
    ]

    opts = [strategy: :one_for_one, name: APIClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
# lib/api_client.ex
defmodule APIClient do
  @cache_ttl :timer.minutes(5)

  def fetch_user(user_id) do
    cache_key = {:user, user_id}

    case Cachex.get(:api_cache, cache_key) do
      {:ok, nil} ->
        fetch_and_cache_user(user_id, cache_key)

      {:ok, user} ->
        {:ok, user, :from_cache}
    end
  end

  defp fetch_and_cache_user(user_id, cache_key) do
    url = "https://api.example.com/users/#{user_id}"

    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, user} <- Jason.decode(body) do
      Cachex.put(:api_cache, cache_key, user, ttl: @cache_ttl)
      {:ok, user, :fetched}
    else
      error -> {:error, error}
    end
  end

  def clear_cache do
    Cachex.clear(:api_cache)
  end
end
```

**Requirements:**
1. Use HTTPoison for HTTP requests
2. Use Jason for JSON parsing
3. Use Cachex for caching
4. All dependencies properly supervised
5. Graceful error handling

**Test:**
```elixir
# First call - fetches from API
{:ok, user, :fetched} = APIClient.fetch_user(123)

# Second call - from cache
{:ok, user, :from_cache} = APIClient.fetch_user(123)

# Clear and fetch again
APIClient.clear_cache()
{:ok, user, :fetched} = APIClient.fetch_user(123)
```

---

### Exercise 4: Process Pool with Poolboy

**Objective:** Use an Erlang library (Poolboy) for process pooling.

**Concepts Reinforced:**
- Erlang interop (Chapter 11)
- Dependencies (Chapter 11)
- Process pools (Chapter 9)
- GenServer (Chapter 6)

**Task:**

```elixir
# mix.exs
defp deps do
  [
    {:poolboy, "~> 1.5"}
  ]
end
```

```elixir
defmodule Worker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def process(pid, data) do
    GenServer.call(pid, {:process, data})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{processed: 0}}
  end

  @impl GenServer
  def handle_call({:process, data}, _from, state) do
    # Simulate work
    Process.sleep(100)
    result = String.upcase(data)
    {:reply, result, %{state | processed: state.processed + 1}}
  end
end
```

```elixir
defmodule WorkerPool do
  def child_spec(_args) do
    pool_args = [
      name: {:local, __MODULE__},
      worker_module: Worker,
      size: 5,
      max_overflow: 2
    ]

    :poolboy.child_spec(__MODULE__, pool_args)
  end

  def process(data) do
    :poolboy.transaction(__MODULE__, fn pid ->
      Worker.process(pid, data)
    end)
  end
end
```

```elixir
defmodule MyApp.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      WorkerPool
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Test:**
```elixir
# Process items concurrently
tasks = for i <- 1..20 do
  Task.async(fn ->
    WorkerPool.process("item_#{i}")
  end)
end

results = Enum.map(tasks, &Task.await/1)
IO.inspect(results)
```

---

## Capstone Project: Production Web Application

### Project Description

Build a complete, production-ready web application that demonstrates proper OTP application structure, dependency management, configuration, and deployment readiness. The application will be a REST API for a blog platform with posts, comments, and user management.

### Architecture

```
BlogAPI (OTP Application)
├── BlogAPI.Application (Supervisor)
│   ├── {Plug.Cowboy, ...} (Web server)
│   ├── BlogAPI.PostCache (ETS-backed cache)
│   ├── BlogAPI.Database (Mock database)
│   └── BlogAPI.RateLimiter (Token bucket)
```

### Requirements

#### 1. Project Structure

```bash
blog_api/
├── mix.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   ├── prod.exs
│   └── runtime.exs
├── lib/
│   ├── blog_api/
│   │   ├── application.ex
│   │   ├── router.ex
│   │   ├── post_cache.ex
│   │   ├── database.ex
│   │   └── rate_limiter.ex
│   └── blog_api.ex
└── test/
    └── blog_api_test.exs
```

#### 2. mix.exs Configuration

```elixir
defmodule BlogAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :blog_api,
      version: "1.0.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {BlogAPI.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"}
    ]
  end
end
```

#### 3. Application Module

```elixir
defmodule BlogAPI.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: BlogAPI.Registry},
      BlogAPI.Database,
      BlogAPI.PostCache,
      BlogAPI.RateLimiter,
      {Plug.Cowboy, scheme: :http, plug: BlogAPI.Router, options: [port: port()]}
    ]

    opts = [strategy: :one_for_one, name: BlogAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port do
    Application.get_env(:blog_api, :port, 4000)
  end
end
```

#### 4. Web Router with Plug

```elixir
defmodule BlogAPI.Router do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :check_rate_limit
  plug :dispatch

  get "/posts" do
    posts = BlogAPI.Database.list_posts()
    send_json(conn, 200, posts)
  end

  get "/posts/:id" do
    case BlogAPI.PostCache.get(id) do
      nil ->
        case BlogAPI.Database.get_post(id) do
          nil -> send_json(conn, 404, %{error: "Post not found"})
          post ->
            BlogAPI.PostCache.put(id, post)
            send_json(conn, 200, post)
        end

      post ->
        send_json(conn, 200, post)
    end
  end

  post "/posts" do
    post = BlogAPI.Database.create_post(conn.body_params)
    BlogAPI.PostCache.put(post.id, post)
    send_json(conn, 201, post)
  end

  put "/posts/:id" do
    case BlogAPI.Database.update_post(id, conn.body_params) do
      nil -> send_json(conn, 404, %{error: "Post not found"})
      post ->
        BlogAPI.PostCache.invalidate(id)
        send_json(conn, 200, post)
    end
  end

  delete "/posts/:id" do
    BlogAPI.Database.delete_post(id)
    BlogAPI.PostCache.invalidate(id)
    send_json(conn, 204, "")
  end

  match _ do
    send_json(conn, 404, %{error: "Not found"})
  end

  defp check_rate_limit(conn, _opts) do
    client_ip = to_string(:inet.ntoa(conn.remote_ip))

    if BlogAPI.RateLimiter.allow?(client_ip) do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
      |> halt()
    end
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end
end
```

#### 5. Database (Mock with GenServer)

```elixir
defmodule BlogAPI.Database do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def list_posts do
    GenServer.call(__MODULE__, :list_posts)
  end

  def get_post(id) do
    GenServer.call(__MODULE__, {:get_post, id})
  end

  def create_post(attrs) do
    GenServer.call(__MODULE__, {:create_post, attrs})
  end

  def update_post(id, attrs) do
    GenServer.call(__MODULE__, {:update_post, id, attrs})
  end

  def delete_post(id) do
    GenServer.call(__MODULE__, {:delete_post, id})
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(:list_posts, _from, posts) do
    {:reply, Map.values(posts), posts}
  end

  def handle_call({:get_post, id}, _from, posts) do
    {:reply, Map.get(posts, id), posts}
  end

  def handle_call({:create_post, attrs}, _from, posts) do
    post = %{
      id: UUID.uuid4(),
      title: attrs["title"],
      body: attrs["body"],
      created_at: DateTime.utc_now()
    }
    {:reply, post, Map.put(posts, post.id, post)}
  end

  def handle_call({:update_post, id, attrs}, _from, posts) do
    case Map.get(posts, id) do
      nil ->
        {:reply, nil, posts}

      post ->
        updated = Map.merge(post, Map.take(attrs, ["title", "body"]))
        {:reply, updated, Map.put(posts, id, updated)}
    end
  end

  def handle_call({:delete_post, id}, _from, posts) do
    {:reply, :ok, Map.delete(posts, id)}
  end
end
```

#### 6. Post Cache (ETS)

```elixir
defmodule BlogAPI.PostCache do
  use GenServer

  @table :post_cache
  @ttl :timer.minutes(5)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get(post_id) do
    case :ets.lookup(@table, post_id) do
      [{^post_id, post, cached_at}] ->
        if fresh?(cached_at), do: post, else: nil

      [] ->
        nil
    end
  end

  def put(post_id, post) do
    :ets.insert(@table, {post_id, post, System.monotonic_time(:millisecond)})
  end

  def invalidate(post_id) do
    :ets.delete(@table, post_id)
  end

  @impl GenServer
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)
    cutoff = now - @ttl

    :ets.select_delete(@table, [
      {{:_, :_, :"$1"}, [{:<, :"$1", cutoff}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp fresh?(cached_at) do
    now = System.monotonic_time(:millisecond)
    (now - cached_at) < @ttl
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @ttl)
  end
end
```

#### 7. Rate Limiter

```elixir
defmodule BlogAPI.RateLimiter do
  use GenServer

  @table :rate_limits
  @window_ms :timer.seconds(60)
  @max_requests 100

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def allow?(client_id) do
    now = System.system_time(:millisecond)

    case :ets.lookup(@table, client_id) do
      [{^client_id, count, window_start}] ->
        if now - window_start > @window_ms do
          :ets.insert(@table, {client_id, 1, now})
          true
        else
          if count < @max_requests do
            :ets.update_counter(@table, client_id, {2, 1})
            true
          else
            false
          end
        end

      [] ->
        :ets.insert(@table, {client_id, 1, now})
        true
    end
  end

  @impl GenServer
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set])
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:cleanup, state) do
    now = System.system_time(:millisecond)
    cutoff = now - @window_ms * 2

    :ets.select_delete(@table, [
      {{:_, :_, :"$1"}, [{:<, :"$1", cutoff}], [true]}
    ])

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @window_ms)
  end
end
```

#### 8. Configuration

```elixir
# config/config.exs
import Config

config :blog_api,
  port: 4000

import_config "#{config_env()}.exs"
```

```elixir
# config/dev.exs
import Config

config :blog_api,
  port: 4000

config :logger, level: :debug
```

```elixir
# config/test.exs
import Config

config :blog_api,
  port: 4001

config :logger, level: :warn
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
  port = System.get_env("PORT") || "4000"
  config :blog_api, port: String.to_integer(port)
end
```

### Testing

```bash
# Start the server
iex -S mix

# In another terminal, test the API
curl http://localhost:4000/posts

curl -X POST http://localhost:4000/posts \
  -H "Content-Type: application/json" \
  -d '{"title": "Hello", "body": "World"}'

curl http://localhost:4000/posts/<id>
```

### Bonus Challenges

1. **Authentication** - Add JWT-based authentication
2. **Database Integration** - Replace mock with real Postgres
3. **WebSocket Support** - Add real-time updates
4. **Pagination** - Implement cursor-based pagination
5. **Metrics** - Add Telemetry for monitoring
6. **Docker** - Create Dockerfile for deployment
7. **Tests** - Comprehensive test suite

### Evaluation Criteria

**Application Structure (25 points)**
- Proper OTP application setup (10 pts)
- Supervision tree design (10 pts)
- Module organization (5 pts)

**Dependencies (20 points)**
- Correct dependency management (10 pts)
- Proper use of third-party libraries (10 pts)

**Configuration (20 points)**
- Environment-specific config (10 pts)
- Runtime configuration (10 pts)

**Features (25 points)**
- REST API endpoints (10 pts)
- Caching layer (5 pts)
- Rate limiting (5 pts)
- Error handling (5 pts)

**Code Quality (10 points)**
- Clean code (5 pts)
- Documentation (3 pts)
- Tests (2 pts)

---

## Success Checklist

Before moving to Chapter 12, ensure you can:

- [ ] Create an OTP application with `mix new --sup`
- [ ] Understand the Application behavior
- [ ] Implement `start/2` callback correctly
- [ ] Configure applications in mix.exs
- [ ] Add and manage dependencies
- [ ] Use Mix environments (dev, test, prod)
- [ ] Configure applications per environment
- [ ] Use config/runtime.exs for runtime config
- [ ] Understand application folder structure
- [ ] Work with library applications
- [ ] List extra_applications correctly
- [ ] Use third-party Erlang libraries
- [ ] Start and stop applications
- [ ] Build deployable systems

---

## Looking Ahead

Chapter 12 explores distributed systems on BEAM:
- **Distributed Erlang** - Connecting nodes
- **Node communication** - Messaging between nodes
- **Global registry** - Finding processes across cluster
- **Network considerations** - Security and reliability

These concepts enable building scalable, distributed applications across multiple machines!
