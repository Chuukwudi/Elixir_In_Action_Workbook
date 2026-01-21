This chapter represents the transition from "Coding" to "Engineering". You are taking your disparate modules and supervision trees and packaging them into a cohesive **OTP Application**—a deployable, configurable unit of software. You will also finally give your system a public face by adding an HTTP server.

---

# Chapter 11: Working with Components – Applications & Web Servers

## 1. Chapter Summary

**The OTP Application**

* **Concept:** An Application is a component that can be started and stopped as a unit. It encapsulates your supervision tree.
* **Structure:**
* **`mix.exs`:** Defines the application metadata (version, dependencies) and the **Callback Module**.
* **Callback Module:** A module that `use Application`. It must implement `start/2`, which spawns the top-level Supervisor.
* **Life Cycle:** When you run `iex -S mix`, Mix starts your application (and all its dependencies) automatically.



**Dependencies**

* **`mix.exs` deps:** You define external libraries here (e.g., `{:poolboy, "~> 1.5"}`).
* **`mix deps.get`:** Fetches the code.
* **Refactoring:** We often replace manual implementations (like our custom database pool) with battle-tested libraries (like `poolboy`).

**Building a Web Server**

* **Cowboy:** The standard, high-performance HTTP server for Erlang/Elixir.
* **Plug:** The interface (specification) for composable web modules.
* **Plug.Router:** A macro that lets you define routes (`get "/path"`) and handle connections (`conn`).
* **Architecture:** The web server is just another **worker** in your supervision tree. It translates HTTP requests into function calls to your existing system (Cache, Server, etc.).
**Configuration**
* **Application Environment:** A global, in-memory key-value store for config settings.
* **`config/runtime.exs`:** The modern way to configure apps. It runs *before* the application boots, allowing you to read System Environment Variables (e.g., `PORT=4000`) and inject them into the application configuration.

---

## 2. Drills

*These drills ensure you are comfortable with the new Mix and Config syntax.*

### Drill 1: Mix Dependencies

**Task:** Write the syntax to add a dependency named `:jason` (a JSON parser), version 1.2 or higher, to your `mix.exs` file.

**Your Solution:**

```elixir
defp deps do
  [
    # ... your code here
  ]
end

```

### Drill 2: Configuration Lookup

**Task:** In your `runtime.exs`, you set `config :my_app, :db_host, "localhost"`. Write the code to retrieve this value inside your application, raising an error if it is missing.

**Your Solution:**

```elixir
host = Application.fetch_env!(...)

```

### Drill 3: Plug Routing

**Task:** Write a simple `Plug.Router` block that handles a `GET` request to `/hello` and responds with "World".

**Your Solution:**

```elixir
use Plug.Router
plug :match
plug :dispatch

get "/hello" do
  send_resp(conn, 200, "World")
end

```

---

## 3. The Project: The Production-Ready Todo System

We will finalize our system structure, replace our manual pool with `poolboy`, and add a Web API.

### Step 1: Conversion to OTP Application

1. Open `mix.exs`. inside `application`, add `mod: {Todo.Application, []}`.
2. Create `lib/todo/application.ex`.
3. Implement `start/2`. It should simply call `Todo.System.start_link()`.
4. **Test:** Run `iex -S mix`. Your system should boot automatically without you typing anything.

### Step 2: Integrating Poolboy (Refactoring)

*The book replaces our manual `Todo.Database` pooling logic with the `poolboy` library.*

1. Add `{:poolboy, "~> 1.5"}` to `deps` in `mix.exs` and run `mix deps.get`.
2. Modify `Todo.Database` (the supervisor/manager):
* Change `child_spec` to return a `:poolboy.child_spec`.
* **Pool Config:** `name: {:local, :todo_database_pool}`, `worker_module: Todo.DatabaseWorker`, `size: 3`.


3. Modify `Todo.Database.store` and `get`:
* Use `:poolboy.transaction(:todo_database_pool, fn worker_pid -> ... end)`.
* Inside the transaction, call the worker functions directly.



### Step 3: The Web Interface (`Todo.Web`)

1. Add `{:plug_cowboy, "~> 2.0"}` to `deps` and `mix deps.get`.
2. Create `lib/todo/web.ex`.
* `use Plug.Router`.
* Add `plug :match` and `plug :dispatch`.


3. **Implement Routes:**
* `post "/add_entry"`:
1. Fetch query params (`conn.params`).
2. Call `Todo.Cache.server_process` to get the list PID.
3. Call `Todo.Server.add_entry`.
4. Respond with `200 OK`.


* `get "/entries"`:
1. Fetch params (list name, date).
2. Call `Todo.Cache.server_process`.
3. Call `Todo.Server.entries`.
4. Format the entries as a string and respond.




4. **Child Spec:** Implement `child_spec/1` in `Todo.Web` to start the Cowboy server (port 5454).

### Step 4: System Integration

1. Add `Todo.Web` to the children list in `Todo.System.start_link`.
2. Start the system (`iex -S mix`).
3. **Test via Browser or Curl:**
* `curl -X POST "http://localhost:5454/add_entry?list=bob&date=2023-01-01&title=Work"`
* `curl "http://localhost:5454/entries?list=bob&date=2023-01-01"`



### Step 5: Configuration (Runtime)

1. Create/Edit `config/runtime.exs`.
2. Read the HTTP port from the system environment: `System.get_env("TODO_PORT")`. Default to 5454.
3. Modify `Todo.Web` to read this port using `Application.get_env` instead of hardcoding it.

---

### Self-Correction Checklist

* [ ] Did you remember to run `mix deps.get` after editing `mix.exs`?
* [ ] Is `Todo.Web` started *after* `Todo.Cache` in the supervision tree? (It depends on the cache, so it should start after).
* [ ] Does your `Todo.Application` module have `use Application` at the top?

---

### Ready for the next step?

We now have a complete, single-node web application. The final frontier is **Distribution**. In **Chapter 12**, we will make multiple Erlang nodes talk to each other to create a distributed cluster.