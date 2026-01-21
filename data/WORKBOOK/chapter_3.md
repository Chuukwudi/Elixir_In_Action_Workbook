This chapter is the "pivot point" for most learners. If you are coming from Java, Python, or JavaScript, this is where you have to let go of `if` statements and `for` loops and embrace the **Elixir way**: **Pattern Matching** and **Recursion**.

---

# Chapter 3: Control Flow – Pattern Matching & Recursion

## 1. Chapter Summary

**Pattern Matching**

* **The Match Operator (`=`):** It is not assignment. It is an assertion. `a = 1` asserts that the left side matches the right side.
* **Destructuring:** You can unpack complex data types (tuples, lists, maps) directly into variables:
* `{a, b} = {1, 2}` binds `a` to 1, `b` to 2.
* `[head | tail] = [1, 2, 3]` binds `head` to 1, `tail` to `[2, 3]`.


* **Pin Operator (`^`):** Use this when you want to match against an *existing* variable's value rather than rebinding it. `^x = 10`.

**Control Flow Constructs**

* **Multiclause Functions:** Instead of writing a big `if/else` block inside a function, you write multiple versions of the same function with different arguments. Elixir executes the first one that matches.


* 
**Guards (`when`):** Used to refine function matching beyond simple patterns (e.g., checking if a number is positive `when x > 0`).


* 
**`cond`:** Useful for checking many different conditions (like an `if/else if/else` chain).


* 
**`case`:** Like a switch statement, but significantly more powerful because it uses pattern matching.


* **`with`:** A pipeline for error handling. It allows you to chain operations and exit early if one fails (returns a non-matching pattern).



**Loops & Iteration**

* **No `while` loops:** Elixir uses recursion.
* 
**Tail Recursion:** If the last action of a function is calling itself, the compiler optimizes it to use no extra stack memory (effectively a `goto`).


* **High-Level Iteration:** In 99% of cases, you won't write recursion manually. You will use **`Enum`** (eager) or **`Stream`** (lazy) modules to map, filter, and reduce collections.



---

## 2. Drills

*These drills force you to use pattern matching instead of conditional logic.*

### Drill 1: Pattern Matching Anatomy

**Task:** Determine which of these matches will **succeed** and which will **fail** (and why).

1. `{a, a} = {1, 2}`
2. `[a, b] = [1, 2, 3]`
3. `[head | _tail] = [1, 2, 3]`
4. `%{name: "Bob"} = %{name: "Bob", age: 44}`

### Drill 2: Guards vs. If

**Task:** Rewrite this function using **Multiclause Functions** and **Guards** instead of `if`.

**Current Code:**

```elixir
def check_age(age) do
  if age < 18 do
    :minor
  else
    :adult
  end
end

```

**Your Solution:**

```elixir
def check_age(age) when ... do
  ...
end

def check_age(age) do
  ...
end

```

### Drill 3: The "With" Expression

**Task:** You have a nested map of data. Use `with` to extract the user's city safely. If any key is missing, return `{:error, :missing_data}`.

**Input Data:**

```elixir
data = %{
  user: %{
    profile: %{
      address: %{
        city: "New York"
      }
    }
  }
}

```

**Your Solution:**

```elixir
def get_city(data) do
  with %{user: user} <- data,
       # ... continue the chain ...
  do
       # return the city
  else
       # handle the error
  end
end

```

---

## 3. The Project: The "TaskManager"

We will build a Task Manager that can handle different types of input commands using **Pattern Matching**.

**Goal:** Create a module that processes a "Todo List".

**Step 1: Define the Structs**
(We haven't fully covered Structs yet, so we will use Maps).
A task looks like this: `%{id: 1, text: "Buy Milk", status: :pending}`.

**Step 2: The Loop (Recursive)**
Create a function `process_tasks/1` that takes a list of tasks.

* **Base Case:** If the list is empty, return `:ok`.
* **Recursive Step:** If the list has items, pattern match the `[head | tail]`.
* Pass the `head` (the single task) to a helper function `perform_task/1`.
* Recursively call `process_tasks(tail)` to handle the rest.



**Step 3: The Performer (Multiclause)**
Create the `perform_task/1` function. It should handle different task statuses using multiple clauses:

1. **Clause 1:** If the task `status` is `:done`, print "Task [ID] is already done."
2. **Clause 2:** If the task `status` is `:pending`, print "Pending Task: [TEXT]".
3. **Clause 3:** If the task `status` is `:failed`, print "Warning! Task [ID] failed."
4. **Catch-all:** If the task format is weird (e.g., missing keys), print "Invalid Task".

**Step 4: The Stream (Lazy Processing)**
(Optional Challenge)
Instead of recursion, imagine you have a file with 10,000 tasks.

* Write a one-liner using `Stream` and `Enum` to:
1. Filter only the tasks where status is `:pending`.
2. Map them to their text strings.
3. Print them.



**Example Usage:**

```elixir
tasks = [
  %{id: 1, text: "Buy Milk", status: :pending},
  %{id: 2, text: "Eat Lunch", status: :done},
  %{id: 3, text: "Call Mom", status: :pending}
]

TaskManager.process_tasks(tasks)
# Output:
# Pending Task: Buy Milk
# Task 2 is already done.
# Pending Task: Call Mom

```

### Self-Correction Checklist

* [ ] Did you use `[head | tail]` for the recursion?
* [ ] Did you use pattern matching in the function arguments for `perform_task`? (e.g., `def perform_task(%{status: :done} = task)`)
* [ ] Did you avoid `if` statements entirely?

---

### Ready for the next step?

Once you have mastered pattern matching and recursion, you have successfully "broken your brain" (in a good way) to think functionally. You are ready for **Chapter 4**, where we will dive deeper into **Data Abstractions** (Maps, Structs, and higher-level data management).