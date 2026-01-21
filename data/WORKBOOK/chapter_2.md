---

# Chapter 2: Building Blocks – Modules, Functions, & Types

## 1. Chapter Summary

**The Interactive Shell (IEx)**

* Elixir is a compiled language, but it offers an interactive shell (`iex`) for experimentation.


* Everything in Elixir is an expression and has a return value.


* The `h` command in IEx provides instant documentation for modules and functions (e.g., `h Enum` or `h Enum.map`).



**Modules & Functions**

* **Modules** are collections of functions, defined with `defmodule`. They act as namespaces.


* 
**Functions** are defined with `def` (public) or `defp` (private).


* **Arity** distinguishes functions. `sum/2` (takes 2 args) and `sum/3` (takes 3 args) are considered completely different functions.


* 
**The Pipe Operator (`|>`)** takes the result of the previous expression and passes it as the *first argument* to the next function.



**The Type System**

* **Atoms:** Constants where the name is the value (e.g., `:ok`, `:error`). `true` and `false` are actually atoms.


* **Tuples:** Fixed-size, contiguous memory (like `{name, age}`). Fast to read, but expensive to modify (requires copying). Used for grouping small, fixed data.


* **Lists:** Linked lists (Head & Tail). Fast to prepend (), slow to append or access by index ().


* 
**Head (`hd`):** The first element.


* 
**Tail (`tl`):** A list containing everything else.




* **Maps:** Key-value stores (`%{key: value}`). The go-to for structured data.


* 
**Strings:** Strictly speaking, these are **binaries** (sequences of bytes) enclosed in double quotes.



**Immutability**

* Data cannot be mutated in place. "Modifying" a tuple or list actually creates a shallow copy.


* Because data is immutable, variables in Elixir are just labels. Rebinding a variable (`a = 1`, then `a = 2`) points the label to a new memory address; it does not overwrite the old memory.



---

## 2. Drills

*These exercises focus on syntax and the properties of Elixir's data structures.*

### Drill 1: List Anatomy

Elixir lists are linked lists, not arrays.
**Task:** Given the list `[1, 2, 3, 4]`, write the result of the following operations without running the code (predict the output):

1. `hd([1, 2, 3, 4])` -> ?
2. `tl([1, 2, 3, 4])` -> ?
3. `[0 | [1, 2, 3, 4]]` -> ? (Hint: This is the cons operator)

### Drill 2: Immutability Trace

**Task:** Trace the values of the variables `a` and `b` through these steps.

```elixir
a = %{name: "Alice", age: 30}
b = Map.put(a, :age, 31)
# Question: What is the value of a.age now?

```

*Why?* Unlike OO languages, `b` is a new copy. `a` remains unchanged.

### Drill 3: Pipeline Refactoring

**Task:** Rewrite the following nested function calls using the pipe operator (`|>`).
*Assume `String.upcase/1`, `String.reverse/1`, and `IO.puts/1` exist.*

**Current Code:**

```elixir
IO.puts(String.reverse(String.upcase("elixir")))

```

**Your Solution:**

```elixir
"elixir"
|> # ... fill in the rest

```

### Drill 4: Tuples vs. Lists

**Task:** For each scenario, decide if you should use a **Tuple** or a **List**.

1. You are reading lines from a 1GB text file and need to store them dynamically.
2. You need to return a function result indicating success or failure along with the data (e.g., "OK" and the "User ID").
3. You need a collection of exactly two coordinates (x, y) for a point on a graph.

---

## 3. The Project: The "User Account" Module

We will build a `User` module to manage user data. Since we don't have control flow (if/else) or recursion yet, we will focus on **data structure creation** and **transformation pipelines**.

**The Goal:** create a module that generates user structs (Maps), extracts their full names, and formats them for display.

**Step 1: Define the Module**
Create a file named `user.ex`. Define a module `User`.

**Step 2: The Factory Function**
Create a function `new_user/2` that takes `name` and `email`.

* It should return a **Map** with keys: `:name`, `:email`, and `:type` (default the type to `:standard`).
* *Constraint:* Use the `\\` syntax for the default argument if you want, or just hardcode it for now.

**Step 3: The Extractor**
Create a function `get_notification_name/1` that takes a user map.

* It should return a string in the format: `"User: [NAME] <[EMAIL]>"`.
* *Hint:* Use String Interpolation `#{}` inside a double-quoted string.

**Step 4: The Formatter Pipeline**
Create a function `format_for_display/1` that takes a user map.

* It should use the **Pipe Operator** to perform these steps:
1. Call `get_notification_name/1` to get the string.
2. Convert the string to uppercase (use `String.upcase/1`).
3. (Optional) If you have Elixir installed, pipe it to `IO.puts/1` to print it.



**Example Usage (Mental Check):**

```elixir
user = User.new_user("Alice", "alice@example.com")
# => %{name: "Alice", email: "alice@example.com", type: :standard}

User.format_for_display(user)
# Should output: "USER: ALICE <ALICE@EXAMPLE.COM>"

```

### Self-Correction Checklist

* [ ] Did you use `defmodule` and `def`?
* [ ] Did you use `%{:key => value}` or `%{key: value}` syntax for the map?
* [ ] Did you use the pipe `|>` in Step 4?

---