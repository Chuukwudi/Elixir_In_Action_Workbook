This chapter represents a major milestone. You are moving from writing simple scripts to building **Abstractions**. In Object-Oriented Programming (OOP), you build Classes. In Elixir, you build **Modules** that operate on **Structs**.

---

# Chapter 4: Data Abstractions – Structs, Modules & Protocols

## 1. Chapter Summary

**Modules as Abstractions**
In Elixir, we don't use classes to couple data and behavior. Instead, we use **Modules** to group functions that operate on a specific data type.

* **Pure & Stateless:** Modules are stateless. You pass data in, and the function returns *new* data out.


* 
**Modifier Functions:** Functions that "change" data (like `add_entry`) actually return a new copy of the data structure with the transformation applied.


* 
**Query Functions:** Functions that return a specific piece of information (like `entries`).



**Structs vs. Maps**
While Maps are flexible key-value stores, **Structs** are more rigid and strictly defined.

* **Compile-time Guarantees:** Structs are defined with `defstruct`. They enforce that only specific keys exist. If you try to access a non-existent field on a struct (e.g., `fraction.d`), you get a compile-time error.


* 
**Under the hood:** A struct is just a Map with a special `__struct__` key.



**Deep Updates**
Because data is immutable, modifying a value deep inside a nested structure (e.g., a map inside a map) requires copying the entire path to that value. Elixir provides macros like `put_in/2` to handle this elegantly.

**Polymorphism via Protocols**
Polymorphism (executing different logic based on input type) is achieved using **Protocols**.

* 
**Interface:** You define a protocol (like an Interface in Java/C#) with function signatures but no body.


* 
**Implementation:** You implement the protocol for specific data types using `defimpl`.


* 
**Built-ins:** Elixir has built-in protocols like `Enumerable` (allows usage with `Enum` module) and `String.Chars` (allows usage with `to_string`).



---

## 2. Drills

*These drills focus on the syntax of Structs and Deep Updates.*

### Drill 1: Defining a Struct

**Task:** Define a module named `User` that contains a **Struct**.

* Fields: `name` (string), `age` (integer, default to 0), and `active` (boolean, default to `true`).

**Your Solution:**

```elixir
defmodule User do
  # ... write the struct definition here
end

```

### Drill 2: Protocol Implementation

**Task:** Implement the `String.Chars` protocol for your `User` struct so that calling `to_string(user)` returns `"User: [NAME]"`.

**Your Solution:**

```elixir
defimpl String.Chars, for: User do
  def to_string(user) do
    # ... return the formatted string
  end
end

```

### Drill 3: Deep Updates

**Task:** Use the `put_in` macro to change "New York" to "Los Angeles" in this nested map structure.

**Input:**

```elixir
data = %{
  profile: %{
    address: %{
      city: "New York"
    }
  }
}

```

**Your Solution:**

```elixir
# Write the one-line put_in statement
new_data = ...

```

---

## 3. The Project: The "Todo List" CRUD

We will build the **TodoList** abstraction discussed in the chapter. This structure will serve as the foundation for the rest of the book.

**The Data Structure:**
We will use a **Struct** to represent the list. It needs:

1. `auto_id`: An integer to track the next unique ID.
2. `entries`: A Map where keys are IDs and values are Entry maps.

### Step 1: Initialize

Create the `TodoList` module and the struct. Implement `new/0` to return an empty struct.

### Step 2: Create (add_entry/2)

Implement `add_entry/2`.

* **Input:** The `TodoList` struct and an entry Map `%{date: ..., title: ...}`.
* **Logic:**
1. Set the entry's `:id` to the current `auto_id`.
2. Add the entry to the `entries` map.
3. Increment `auto_id`.


* **Return:** The updated `TodoList` struct.

### Step 3: Read (entries/2)

Implement `entries/2`.

* **Input:** The `TodoList` struct and a `Date`.
* 
**Logic:** Filter the `entries` map values to find only those matching the given date.



### Step 4: Update (update_entry/3)

Implement `update_entry/3`.

* **Input:** `todo_list`, `entry_id`, and an `updater_fun` (lambda).
* **Logic:**
1. Check if the ID exists.
2. If it does, call the `updater_fun` on the old entry to get the new entry.
3. Put the new entry back into the map.





### Step 5: Delete (delete_entry/2) **[Challenge]**

*The book left this as an exercise for you.*

* **Input:** `todo_list` and `entry_id`.
* **Logic:** Remove the entry with the given ID from the `entries` map.
* **Hint:** Look at `Map.delete/2`.

### Step 6: CSV Importer **[Bonus Challenge]**

*The book also left this as an exercise.*
Create a module `TodoList.CsvImporter` with a function `import(filename)`.

1. Read the file using `File.stream!`.
2. Parse each line (e.g., `"2023-12-19,Dentist"`) into a map `%{date: ~D[...], title: "..."}`.
3. Use `TodoList.new/1` (which you might need to implement using `Enum.reduce`) to build a list from these entries.



---

### Self-Correction Checklist

* [ ] Does your `add_entry` function return a **new** struct? (It must not try to mutate the old one).
* [ ] Did you use `defstruct` inside the `TodoList` module?
* [ ] Does your `update_entry` handle the case where the ID does not exist? (It should simply return the list unchanged) .



---

### Ready for the next step?

You now have a functional core for a Todo application. In **Chapter 5**, we will introduce the most famous feature of Elixir/Erlang: **Concurrency**. We will take this static code and make it run inside long-lived **Processes**.