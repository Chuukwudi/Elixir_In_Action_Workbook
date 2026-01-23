# Chapter 2: Building Blocks - Learning Exercises

## Chapter Summary

Chapter 2 provides a comprehensive tour of Elixir's fundamental building blocks, including the interactive shell (iex), variables, modules, functions, and the type system built on Erlang's foundation. The chapter emphasizes Elixir's immutable data model, where modifications create new data structures that share memory efficiently, and introduces key data types including numbers, atoms, tuples, lists, maps, binaries, and strings, along with higher-level abstractions like ranges and keyword lists. Understanding these primitives and how modules compile to .beam files running on BEAM is essential for leveraging Elixir's functional programming paradigm and runtime characteristics.

---

## Concept Drills

These exercises focus on understanding the fundamental concepts introduced in Chapter 2.

### Drill 1: Interactive Shell Basics

**Objective:** Get comfortable with the iex shell and understand expression evaluation.

**Task:** Start iex and perform the following operations:
1. Calculate `(10 + 5) * 3 - 7`
2. Try to enter an incomplete expression (missing closing parenthesis), then use `#iex:break` to abort it
3. Bind a variable `price` to 99.99
4. Calculate the total for 3 items using the `price` variable
5. Rebind `price` to 89.99 and recalculate

**Expected Output:**
- Correct arithmetic result for #1
- Successfully aborting the incomplete expression
- Variable binding and usage demonstrations
- Understanding that rebinding creates a new memory location

---

### Drill 2: Module and Function Creation

**Objective:** Practice defining modules and functions with proper syntax.

**Task:** Create a module called `Temperature` with the following functions:
1. `f_to_c/1` - converts Fahrenheit to Celsius: `(F - 32) * 5/9`
2. `c_to_f/1` - converts Celsius to Fahrenheit: `C * 9/5 + 32`
3. `c_to_k/1` - converts Celsius to Kelvin: `C + 273.15`

Save this in a file called `temperature.ex`, load it in iex, and test all three functions.

**Expected Output:**
```elixir
Temperature.f_to_c(32)    # => 0.0
Temperature.c_to_f(0)     # => 32.0
Temperature.c_to_k(0)     # => 273.15
```

**Success Criteria:**
- Module compiles without errors
- All functions return correct values
- Proper function naming conventions used

---

### Drill 3: Understanding Arity

**Objective:** Understand how arity distinguishes functions and implement default arguments.

**Task:** Create a module `Greeter` with:
1. `hello/0` - returns "Hello, World!"
2. `hello/1` - takes a name and returns "Hello, [name]!"
3. `hello/2` - takes a name and greeting, returns "[greeting], [name]!"
4. Refactor using default arguments to reduce code duplication

**Expected Output:**
```elixir
Greeter.hello()              # => "Hello, World!"
Greeter.hello("Alice")       # => "Hello, Alice!"
Greeter.hello("Bob", "Hi")   # => "Hi, Bob!"
```

**Success Criteria:**
- Three distinct functions work correctly
- Refactored version using defaults produces same behavior
- Understanding that arity creates different functions

---

### Drill 4: Atoms and Pattern Matching

**Objective:** Work with atoms as constants and understand their properties.

**Task:** 
1. Create several atom variables: `:ok`, `:error`, `:pending`, `:"contains spaces"`
2. Verify that `AnAtom == :"Elixir.AnAtom"`
3. Create a function `status_message/1` that takes a status atom and returns:
   - `:ok` → "Success!"
   - `:error` → "Something went wrong"
   - `:pending` → "Processing..."
   - anything else → "Unknown status"

**Expected Output:**
Demonstration of atom equality and a working status_message function.

**Success Criteria:**
- Understanding atoms are compile-time constants
- Proper use of atoms in function arguments
- Awareness of atom table implications

---

### Drill 5: Tuples vs Lists

**Objective:** Understand when to use tuples versus lists.

**Task:** 
1. Create a tuple representing a person: `{"Alice", 30, "Engineer"}`
2. Extract the age using `elem/2`
3. Create a modified version with age 31 using `put_elem/3`
4. Create a list of prime numbers: `[2, 3, 5, 7, 11]`
5. Get the length using `length/1`
6. Add 13 to the beginning using `[13 | list]`
7. Add 17 to the end using `list ++ [17]`

Write an explanation (1-2 paragraphs) of when to use tuples vs. lists based on the operations.

**Expected Output:**
- Working code for all operations
- Clear explanation of tuple (fixed-size, O(1) access) vs. list (dynamic, O(n) operations) trade-offs

---

### Drill 6: Map Manipulation

**Objective:** Work with maps for both dynamic data and structured records.

**Task:** Create two types of map usage:

**Part A - Dynamic Map:**
1. Create an empty map
2. Add key-value pairs for user counts by day: `monday: 100, tuesday: 150`
3. Fetch Tuesday's count
4. Update Monday's count to 120

**Part B - Structured Data:**
1. Create a map representing a book: `%{title: "Elixir in Action", author: "Saša Jurić", pages: 400}`
2. Access the author using dot notation
3. Update the pages to 450 using the update syntax `%{book | pages: 450}`

**Expected Output:**
Both map types working correctly with appropriate syntax for each use case.

---

### Drill 7: Immutability Demonstration

**Objective:** Prove that data is immutable in Elixir.

**Task:** 
1. Create a list: `original = [1, 2, 3]`
2. Create `modified = original ++ [4]`
3. Print both `original` and `modified`
4. Explain what happened in memory (draw or describe)
5. Do the same with a tuple

**Expected Output:**
- `original` remains `[1, 2, 3]`
- `modified` is `[1, 2, 3, 4]`
- Clear explanation that original data is unchanged, new data shares memory where possible

---

### Drill 8: String Operations

**Objective:** Work with binary strings and understand string interpolation.

**Task:** 
1. Create a string with interpolation: `"Result: #{10 + 5}"`
2. Create a multi-line string using `"""`
3. Concatenate two strings using `<>`
4. Use a sigil: `~s(String with "quotes")`
5. Convert between binary string and character list

**Expected Output:**
Working examples of each string operation and understanding when to use each syntax.

---

## Integration Exercises

These exercises combine concepts from Chapter 2 with principles from Chapter 1.

### Exercise 1: Data Pipeline with Pipe Operator

**Objective:** Use Chapter 2's pipe operator to build readable transformations, reinforcing Chapter 1's emphasis on composability.

**Concepts Reinforced:**
- Pipe operator (Chapter 2)
- Function composition (Chapter 1)
- Data transformation mindset

**Task:** Build a data processing pipeline for user data:

1. Create a module `DataPipeline` with these transformation functions:
   - `parse_csv_line/1` - takes a string "Alice,30,Engineer", returns a map
   - `validate_age/1` - returns map if age >= 18, else returns `{:error, "Too young"}`
   - `normalize_name/1` - capitalizes the name
   - `format_output/1` - creates a formatted string

2. Create a `process/1` function that chains all transformations using `|>`

3. Handle errors gracefully (you'll learn more about this later, for now just pattern match)

**Example:**
```elixir
"alice,30,engineer"
|> DataPipeline.parse_csv_line()
|> DataPipeline.validate_age()
|> DataPipeline.normalize_name()
|> DataPipeline.format_output()
# => "Name: Alice, Age: 30, Job: Engineer"
```

**Success Criteria:**
- Pipeline is readable left-to-right
- Each function does one thing well
- Functions are pure (no side effects except I/O)
- Clear data flow through the pipeline

**Bonus Challenge:** Add timing to measure how long the pipeline takes (use `:timer.tc/1`)

---

### Exercise 2: Keyword Lists for Configuration

**Objective:** Use keyword lists for flexible function options, preparing for the configurable systems from Chapter 1.

**Concepts Reinforced:**
- Keyword lists (Chapter 2)
- Optional parameters pattern
- Flexibility in system design (Chapter 1)

**Task:** Create a `Logger` module that accepts configuration options:

```elixir
defmodule Logger do
  def log(message, opts \\ []) do
    # Extract options with defaults:
    # - level: :info (can be :debug, :info, :warn, :error)
    # - timestamp: true
    # - prefix: ""
    
    # Format and return the log message
  end
end
```

**Usage examples:**
```elixir
Logger.log("System started")
Logger.log("Debug info", level: :debug, prefix: "[APP]")
Logger.log("Error occurred", level: :error, timestamp: false)
```

**Success Criteria:**
- Works with no options (uses defaults)
- Accepts any combination of options
- Option order doesn't matter
- Demonstrates the optional parameters pattern from Elixir standard library

**Extension:** Add a `format/2` private function that handles the formatting logic.

---

### Exercise 4: Type System and Runtime Behavior

**Objective:** Understand how Elixir's dynamic type system works at runtime and relates to BEAM's reliability.

**Concepts Reinforced:**
- Dynamic typing (Chapter 2)
- Runtime behavior (Chapter 2)
- Error isolation (Chapter 1)

**Task:** Create a `Calculator` module with a function `divide/2` that demonstrates:

1. Dynamic typing by accepting any types
2. Type checking at runtime
3. Returning tagged tuples for errors: `{:ok, result}` or `{:error, reason}`

```elixir
defmodule Calculator do
  def divide(a, b) do
    # Check if both are numbers
    # Check if b is not zero
    # Return {:ok, result} or {:error, reason}
  end
  
  def safe_divide(a, b, default) do
    # Use divide/2 and return default on error
  end
end
```

**Test cases:**
```elixir
Calculator.divide(10, 2)        # => {:ok, 5.0}
Calculator.divide(10, 0)        # => {:error, "Division by zero"}
Calculator.divide(10, "2")      # => {:error, "Arguments must be numbers"}
Calculator.safe_divide(10, 0, :infinity)  # => :infinity
```

**Success Criteria:**
- Proper runtime type checking
- Tagged tuple return values
- Safe wrapper function
- Understanding that this pattern helps with fault tolerance

**Reflection:** How does returning `{:ok, result}` or `{:error, reason}` relate to the fault tolerance concepts from Chapter 1?

---

### Exercise 5: Module Compilation and Runtime

**Objective:** Understand the relationship between source code, modules, and the BEAM runtime.

**Concepts Reinforced:**
- Module compilation (Chapter 2)
- BEAM runtime (Chapter 1 & 2)
- Code organization

**Task:** 

**Part A - Compilation Experiment:**
1. Create three modules in one file `geometry.ex`:
   - `Circle` with `area/1` and `circumference/1`
   - `Rectangle` with `area/2` and `perimeter/2`
   - `Triangle` with `area/2` (base, height)

2. Compile using `elixirc geometry.ex`
3. Observe how many .beam files are created
4. Start iex from that directory and use the modules

**Part B - Module Naming:**
1. Create a module with a hierarchical name: `Geometry.Shapes.Circle`
2. Verify it compiles to `Elixir.Geometry.Shapes.Circle.beam`
3. Create an alias and demonstrate equivalence:
   ```elixir
   alias Geometry.Shapes.Circle
   Circle == :"Elixir.Geometry.Shapes.Circle"  # => true
   ```

**Expected Output:**
- Understanding that each module = one .beam file
- Module names are atoms
- Hierarchical naming is just a convention

**Success Criteria:**
- Correct number of .beam files
- Working module loading
- Understanding atom-based module system

---

## Capstone Project: Contact Management System

### Project Description

Build a contact management system that demonstrates all major concepts from Chapter 2 while considering the high-availability principles from Chapter 1. This system will manage contacts with various operations, demonstrating proper use of Elixir's type system, modules, functions, and data structures.

### Project Requirements

Create a complete contact management system with the following components:

#### 1. Core Module: `ContactManager`

**Data Structure:**
Each contact should be a map with:
- `:id` - unique integer
- `:name` - string
- `:email` - string
- `:phone` - string
- `:tags` - list of atoms (e.g., `:work`, `:personal`, `:vip`)
- `:created_at` - DateTime
- `:notes` - string (optional)

**Required Functions:**

**Public API:**
```elixir
create_contact(name, email, phone, opts \\ [])
# Returns: {:ok, contact} or {:error, reason}

get_contact(id)
# Returns: {:ok, contact} or {:error, :not_found}

list_contacts()
# Returns: list of all contacts

update_contact(id, fields)
# Returns: {:ok, updated_contact} or {:error, reason}

delete_contact(id)
# Returns: {:ok, deleted_contact} or {:error, :not_found}

search_by_tag(tag)
# Returns: list of contacts with the given tag

search_by_name(partial_name)
# Returns: list of contacts whose name contains partial_name
```

**Private Helper Functions:**
- `validate_contact/1` - ensures all required fields present
- `validate_email/1` - basic email format validation
- `generate_id/0` - creates unique IDs
- `normalize_name/1` - capitalizes name properly

#### 2. Support Module: `ContactManager.Formatter`

Functions for formatting contact data:
```elixir
format_contact(contact)
# Returns: nicely formatted string representation

format_list(contacts)
# Returns: formatted string of all contacts

export_csv(contacts)
# Returns: CSV string representation
```

#### 3. Support Module: `ContactManager.Query`

Advanced query functions:
```elixir
filter_by(contacts, field, value)
# Generic filter function

sort_by(contacts, field)
# Sort contacts by any field

group_by_tag(contacts)
# Returns: map of tag => [contacts]
```

#### 4. Testing Module: `ContactManager.Examples`

Provide example usage and sample data:
```elixir
sample_contacts()
# Returns: list of 5-10 sample contacts

demo()
# Runs a demonstration of all functionality
```

### Technical Requirements

1. **Immutability:**
   - All data transformations must create new data structures
   - No state stored in module attributes (for now)
   - Demonstrate memory sharing in comments

2. **Type Usage:**
   - Use appropriate types for each field
   - Demonstrate tuples for fixed data, lists for collections, maps for records
   - Use atoms for tags and status codes
   - Use keyword lists for optional parameters

3. **Function Design:**
   - Functions should be small (< 10 lines ideally)
   - Use pipe operator where appropriate
   - Public/private distinction clear
   - Pattern matching in function heads where useful

4. **Error Handling:**
   - Return `{:ok, result}` or `{:error, reason}` tuples
   - Don't let functions crash (we'll learn proper error handling later)
   - Validate inputs

5. **Documentation:**
   - Add `@moduledoc` for each module
   - Add `@doc` for each public function
   - Include examples in docs
   - Add `@spec` type specifications

### Deliverables

1. **Source Files:**
   - `contact_manager.ex` - core module
   - `formatter.ex` - formatting functions
   - `query.ex` - query functions
   - `examples.ex` - sample data and demos

2. **Demo Script:**
   - `demo.exs` - script that demonstrates all functionality
   - Should run with `elixir demo.exs`
   - Should show creating, updating, querying, and deleting contacts

3. **Documentation:**
   - README.md with:
     - How to compile and run
     - API overview
     - Example usage
     - Design decisions explanation

4. **Analysis Document:**
   - Explain how immutability benefits this system
   - Describe how you'd extend this for concurrency (thinking ahead to later chapters)
   - Identify which operations are O(1), O(n), etc.
   - Discuss trade-offs in your design choices

### Bonus Challenges

1. **Import/Export:**
   - Add `import_csv/1` function
   - Add `export_json/1` function
   - Handle malformed data gracefully

2. **Advanced Queries:**
   - Implement `search/1` with a mini query DSL
   - Example: `search(%{name: "John", tag: :work})`
   - Support multiple criteria

3. **Validation:**
   - Add phone number format validation
   - Add duplicate detection (same email)
   - Add custom validation rules via options

4. **Batch Operations:**
   - `bulk_create/1` - create multiple contacts
   - `bulk_update/2` - update multiple contacts
   - `bulk_tag/2` - add tag to multiple contacts
   - Use pipelines for efficient processing

5. **Statistics:**
   - `stats/0` - return statistics map
   - Total contacts, contacts per tag, etc.
   - Demonstrate use of `Enum` module functions

### Evaluation Criteria

**Understanding Fundamentals (40 points)**
- Correct use of Elixir types (10 pts)
- Proper immutability (10 pts)
- Appropriate data structures (10 pts)
- Module organization (10 pts)

**Code Quality (30 points)**
- Function design and composition (10 pts)
- Pattern matching usage (10 pts)
- Error handling (5 pts)
- Code style and conventions (5 pts)

**Documentation (15 points)**
- Module and function docs (7 pts)
- Type specifications (4 pts)
- Example usage (4 pts)

**Design Thinking (15 points)**
- Considering concurrency (from Ch. 1) (5 pts)
- Performance awareness (5 pts)
- Extensibility (5 pts)

### Example Usage

```elixir
# Start iex with all modules loaded
$ iex contact_manager.ex formatter.ex query.ex

# Create contacts
iex> {:ok, alice} = ContactManager.create_contact(
  "Alice Smith",
  "alice@example.com",
  "555-1234",
  tags: [:work, :vip]
)

iex> {:ok, bob} = ContactManager.create_contact(
  "Bob Jones",
  "bob@example.com",
  "555-5678",
  tags: [:personal]
)

# List all contacts
iex> ContactManager.list_contacts()
|> ContactManager.Formatter.format_list()
|> IO.puts()

# Search
iex> ContactManager.search_by_tag(:vip)

# Update
iex> ContactManager.update_contact(alice.id, %{phone: "555-9999"})

# Delete
iex> ContactManager.delete_contact(bob.id)

# Query operations
iex> ContactManager.list_contacts()
|> ContactManager.Query.filter_by(:tags, :work)
|> ContactManager.Query.sort_by(:name)

# Export
iex> ContactManager.list_contacts()
|> ContactManager.Formatter.export_csv()
|> IO.puts()
```

### Tips for Success

1. **Start Small:** Build one module at a time, test thoroughly
2. **Use iex:** Load modules incrementally and test each function
3. **Think Immutable:** Every operation returns new data
4. **Composition:** Build complex functions from simple ones
5. **Pattern Match:** Use it in function heads for elegant code
6. **Tag Errors:** Always return `{:ok, value}` or `{:error, reason}`
7. **Document:** Write docs as you code, not after
8. **Consider Chapter 1:** Think about how this would work with processes

### Connection to Chapter 1 Concepts

This project reinforces Chapter 1 by:

1. **Fault Tolerance:** Using tagged tuples for errors prevents crashes
2. **Scalability:** Design considers future process-per-contact model
3. **Immutability:** All operations create new data, supporting concurrent access
4. **Module Design:** Clear boundaries prepare for distributed systems

### Reflection Questions

After completing the project, consider:

1. How does immutability make this system more reliable?
2. If each contact operation happened in a separate process, what would change?
3. Where are the performance bottlenecks? (O(n) operations)
4. How would you handle 1 million contacts?
5. What would change if this system needed to run on multiple machines?

---

## Additional Practice

### Quick Challenges

1. **Type Exploration:**
   - Create examples of every type mentioned in Chapter 2
   - Test what happens when you combine different types
   - Explore the limits (e.g., integer size, tuple size)

2. **Module Games:**
   - Create a module hierarchy 3 levels deep
   - Use aliases to shorten names
   - Experiment with `import` vs. `alias`

3. **Function Variations:**
   - Write the same function 3 ways: explicit, pipe, capture operator
   - Compare readability
   - Measure if there's any performance difference

4. **Data Structure Practice:**
   - Implement a shopping cart using different data structures
   - Compare maps vs. keyword lists vs. lists of tuples
   - Justify your choice for each use case

### Debugging Exercises

Fix the errors in these code snippets:

```elixir
# Exercise 1
defmodule Broken1 do
  def calculate(x)
    x * 2
  end
end

# Exercise 2
defmodule Broken2 do
  def process(data) do
    result = data
    |> transform
    |> validate
    |> save
  end
end

# Exercise 3
person = %{name: "Alice", age: 30}
person.address  # What happens?

# Exercise 4
list = [1, 2, 3]
list[1]  # What's the problem?
```

---

## Success Checklist

Before moving to Chapter 3, ensure you can:

- [ ] Start and use the iex shell effectively
- [ ] Create modules and functions with proper syntax
- [ ] Understand how arity distinguishes functions
- [ ] Use atoms appropriately as constants
- [ ] Explain the difference between tuples and lists
- [ ] Work with maps for both dynamic and structured data
- [ ] Understand and leverage immutability
- [ ] Use the pipe operator for readable transformations
- [ ] Create and use anonymous functions/lambdas
- [ ] Distinguish between binary strings and charlists
- [ ] Organize code into modules with public/private functions
- [ ] Use keyword lists for optional parameters
- [ ] Understand how modules compile to .beam files
- [ ] Explain the relationship between module names and atoms
- [ ] Use various ways to start the runtime (iex, elixir, mix)

---

## Looking Ahead

Chapter 3 will cover:
- Pattern matching (building on function heads from Ch. 2)
- Control flow (if, case, cond)
- Loops via recursion (using immutable lists from Ch. 2)
- Comprehensions (elegant iteration)

The skills from Chapter 2 (especially immutability, function composition, and data structures) are fundamental to everything that follows!