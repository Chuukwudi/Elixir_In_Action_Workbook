# Chapter 3: Control Flow - Learning Exercises

## Chapter Summary

Chapter 3 introduces pattern matching as the foundation for declarative control flow in Elixir, enabling elegant destructuring of data and powerful multiclause functions that branch based on both shape and values. The chapter covers classical conditional constructs (if, case, cond, with) alongside the functional approach to loops through recursion, tail-call optimization, and higher-order functions from the Enum module. Comprehensions and streams provide sophisticated tools for composable, lazy transformations that can process arbitrarily large or infinite collections efficiently without building intermediate data structures.

---

## Concept Drills

These exercises focus on understanding the fundamental concepts introduced in Chapter 3.

### Drill 1: Basic Pattern Matching

**Objective:** Master the match operator and understand when matches succeed or fail.

**Task:** Without running the code, predict which of these pattern matches will succeed and which will raise MatchError. Then verify your predictions in iex:

```elixir
# 1
{a, b} = {1, 2}

# 2
{a, b, c} = {1, 2}

# 3
[head | tail] = [1, 2, 3]

# 4
[head | tail] = []

# 5
{:ok, result} = {:ok, 42}

# 6
{:ok, result} = {:error, "failed"}

# 7
%{name: name} = %{name: "Alice", age: 30}

# 8
%{name: name, job: job} = %{name: "Alice", age: 30}

# 9
[a, a] = [5, 5]

# 10
[a, a] = [5, 6]
```

**Expected Output:**
- Correct predictions for all 10 cases
- Understanding of why each succeeds or fails
- Explanation of pattern matching rules

---

### Drill 2: Destructuring Complex Data

**Objective:** Use pattern matching to extract nested data structures.

**Task:** Given the following data structure representing a person's profile:

```elixir
profile = %{
  user: %{name: "Alice", age: 30},
  address: %{street: "123 Main St", city: "Portland"},
  contacts: [
    {:email, "alice@example.com"},
    {:phone, "555-1234"}
  ]
}
```

Write pattern matches to extract:
1. Just the user's name
2. Both the city and the first contact (email tuple)
3. The phone number from the contacts list

**Expected Output:**
```elixir
# 1
%{user: %{name: name}} = profile
# name => "Alice"

# 2
%{address: %{city: city}, contacts: [email_tuple | _]} = profile
# city => "Portland", email_tuple => {:email, "alice@example.com"}

# 3
%{contacts: [_, {:phone, phone}]} = profile
# phone => "555-1234"
```

---

### Drill 3: Multiclause Functions

**Objective:** Create functions with multiple clauses using pattern matching.

**Task:** Create a `Geometry` module with an `area/1` function that calculates the area for different shapes:

```elixir
defmodule Geometry do
  # Implement area/1 for:
  # {:rectangle, width, height}
  # {:square, side}
  # {:circle, radius}
  # {:triangle, base, height}
  # Any other shape should return {:error, :unknown_shape}
end
```

**Test Cases:**
```elixir
Geometry.area({:rectangle, 4, 5})  # => 20
Geometry.area({:square, 5})        # => 25
Geometry.area({:circle, 3})        # => 28.26 (approx, use 3.14 for pi)
Geometry.area({:triangle, 6, 4})   # => 12.0
Geometry.area({:hexagon, 5})       # => {:error, :unknown_shape}
```

**Success Criteria:**
- All test cases pass
- Clauses are in the correct order
- Default clause handles unknown shapes

---

### Drill 4: Guards in Action

**Objective:** Use guards to refine pattern matching with runtime conditions.

**Task:** Implement a `NumberClassifier` module with these functions:

```elixir
defmodule NumberClassifier do
  # classify/1 - returns :positive, :negative, or :zero
  # Only accepts numbers; raises FunctionClauseError for non-numbers

  # fizzbuzz/1 - returns:
  #   "FizzBuzz" if divisible by both 3 and 5
  #   "Fizz" if divisible by 3
  #   "Buzz" if divisible by 5
  #   The number itself (as string) otherwise
  # Only works for integers
end
```

**Expected Output:**
```elixir
NumberClassifier.classify(5)    # => :positive
NumberClassifier.classify(-3)   # => :negative
NumberClassifier.classify(0)    # => :zero
NumberClassifier.classify(:x)   # => FunctionClauseError

NumberClassifier.fizzbuzz(15)   # => "FizzBuzz"
NumberClassifier.fizzbuzz(9)    # => "Fizz"
NumberClassifier.fizzbuzz(10)   # => "Buzz"
NumberClassifier.fizzbuzz(7)    # => "7"
```

**Success Criteria:**
- Proper use of guards (is_number/1, is_integer/1, rem/2)
- Correct ordering of clauses
- FizzBuzz clauses in the right order

---

### Drill 5: Recursion Basics

**Objective:** Implement simple recursive functions.

**Task:** Create a `RecursionPractice` module with:

```elixir
defmodule RecursionPractice do
  # countdown/1 - prints numbers from n down to 1
  def countdown(n) do
    # Your implementation
  end

  # list_length/1 - calculates length of a list recursively
  def list_length(list) do
    # Your implementation
  end

  # range/2 - creates a list of numbers from `from` to `to`
  # e.g., range(3, 7) => [3, 4, 5, 6, 7]
  def range(from, to) do
    # Your implementation
  end
end
```

**Expected Output:**
```elixir
RecursionPractice.countdown(3)
# Prints: 3, 2, 1 (each on new line)

RecursionPractice.list_length([1, 2, 3, 4])  # => 4
RecursionPractice.list_length([])            # => 0

RecursionPractice.range(3, 7)   # => [3, 4, 5, 6, 7]
RecursionPractice.range(5, 5)   # => [5]
```

---

### Drill 6: Tail Recursion

**Objective:** Convert recursive functions to tail-recursive versions.

**Task:** Take the `list_length/1` and `range/2` functions from Drill 5 and implement tail-recursive versions:

```elixir
defmodule TailRecursion do
  # Tail-recursive list_length
  def list_length(list) do
    do_length(list, 0)
  end

  defp do_length([], acc), do: # Complete this
  defp do_length([_ | tail], acc), do: # Complete this

  # Tail-recursive range
  def range(from, to) do
    # Your implementation with accumulator
  end
end
```

**Success Criteria:**
- Functions produce the same results as non-tail-recursive versions
- Private helper functions use accumulators
- Last operation is the recursive call (tail position)

---

### Drill 7: Higher-Order Functions with Enum

**Objective:** Master common Enum functions for list transformations.

**Task:** Given a list of products:

```elixir
products = [
  %{name: "Laptop", price: 999, category: :electronics},
  %{name: "Mouse", price: 25, category: :electronics},
  %{name: "Desk", price: 299, category: :furniture},
  %{name: "Chair", price: 199, category: :furniture},
  %{name: "Monitor", price: 349, category: :electronics}
]
```

Use Enum functions to:
1. Get all product names (use `Enum.map`)
2. Filter only electronics under $500 (use `Enum.filter`)
3. Calculate total price of all products (use `Enum.reduce`)
4. Find the most expensive product (use `Enum.max_by`)
5. Group products by category (use `Enum.group_by`)

**Expected Output:**
```elixir
# 1
["Laptop", "Mouse", "Desk", "Chair", "Monitor"]

# 2
[%{name: "Mouse", ...}, %{name: "Monitor", ...}]

# 3
1871

# 4
%{name: "Laptop", price: 999, ...}

# 5
%{
  electronics: [%{name: "Laptop", ...}, %{name: "Mouse", ...}, %{name: "Monitor", ...}],
  furniture: [%{name: "Desk", ...}, %{name: "Chair", ...}]
}
```

---

### Drill 8: Comprehensions

**Objective:** Use comprehensions for data transformation and filtering.

**Task:**

1. Generate a list of all coordinates in a 5x5 grid: `[{0,0}, {0,1}, ..., {4,4}]`
2. Generate a map where keys are numbers 1-10 and values are their squares
3. From a list of strings, create a list of {string, length} tuples for strings longer than 3 characters
4. Create a multiplication table (1-12) as a formatted list of strings

**Expected Output:**
```elixir
# 1
for x <- 0..4, y <- 0..4, do: {x, y}

# 2
for n <- 1..10, into: %{}, do: {n, n * n}

# 3
strings = ["hi", "hello", "ok", "world", "bye"]
for s <- strings, String.length(s) > 3, do: {s, String.length(s)}
# => [{"hello", 5}, {"world", 5}]

# 4
for x <- 1..12, y <- 1..12, do: "#{x} x #{y} = #{x * y}"
```

---

### Drill 9: Streams vs. Enum

**Objective:** Understand the difference between lazy (Stream) and eager (Enum) evaluation.

**Task:**

1. Create a stream that generates infinite natural numbers starting from 1
2. Take the first 100 odd numbers from this stream
3. Write a function that reads a file and returns only lines containing the word "error" (case-insensitive)
4. Explain when you would use Stream instead of Enum

**Implementation:**
```elixir
defmodule StreamPractice do
  def infinite_naturals do
    # Generate infinite stream starting at 1
  end

  def first_n_odds(n) do
    # Use infinite_naturals and take n odd numbers
  end

  def error_lines!(file_path) do
    # Use File.stream! and Stream operations
  end
end
```

**Success Criteria:**
- Infinite stream works without crashing
- File is read line-by-line without loading entire file
- Understanding of lazy vs. eager evaluation

---

## Integration Exercises

These exercises combine concepts from Chapter 3 with concepts from Chapters 1 and 2.

### Exercise 1: Enhanced Contact Validation

**Objective:** Use pattern matching and guards to improve the contact manager from Chapter 2.

**Concepts Reinforced:**
- Maps and structs (Chapter 2)
- Pattern matching (Chapter 3)
- Guards (Chapter 3)
- Tagged tuples for error handling (Chapter 2)

**Task:** Extend the contact manager with validation using pattern matching:

```elixir
defmodule ContactValidator do
  # Validate a contact map using pattern matching and guards
  # Returns {:ok, contact} or {:error, reasons}

  def validate(contact) when is_map(contact) do
    # Use with expression to validate:
    # - name is present and a non-empty string
    # - email is present and contains "@"
    # - phone matches pattern "XXX-XXXX" or "XXX-XXX-XXXX"
    # - age (if present) is between 0 and 150
  end

  # Pattern match on specific error cases
  def handle_validation_result({:ok, contact}) do
    # Process valid contact
  end

  def handle_validation_result({:error, reasons}) do
    # Format error message
  end
end
```

**Success Criteria:**
- Use `with` expression for chaining validations
- Pattern match on success/failure tuples
- Guards ensure type and value correctness
- Clear error messages for invalid data

---

### Exercise 2: Recursive List Operations

**Objective:** Implement list manipulation functions using recursion and pattern matching.

**Concepts Reinforced:**
- Lists and immutability (Chapter 2)
- Recursion (Chapter 3)
- Pattern matching (Chapter 3)
- Tail-call optimization (Chapter 3)

**Task:** Create a `ListOps` module with these functions:

```elixir
defmodule ListOps do
  # filter/2 - implement Enum.filter using recursion
  def filter(list, predicate_fn) do
    # Your tail-recursive implementation
  end

  # map/2 - implement Enum.map using recursion
  def map(list, transform_fn) do
    # Your tail-recursive implementation
  end

  # flatten/1 - flattens nested lists
  # flatten([1, [2, [3, 4], 5]]) => [1, 2, 3, 4, 5]
  def flatten(list) do
    # Your implementation
  end

  # zip/2 - combines two lists into list of tuples
  # zip([1, 2, 3], [:a, :b, :c]) => [{1, :a}, {2, :b}, {3, :c}]
  def zip(list1, list2) do
    # Your implementation
  end
end
```

**Success Criteria:**
- All functions work like their Enum equivalents
- Tail-recursive where appropriate
- Proper base cases for recursion
- Pattern matching on list structure

---

### Exercise 3: Data Processing Pipeline

**Objective:** Build a composable data pipeline using pipe operator, Enum/Stream, and comprehensions.

**Concepts Reinforced:**
- Pipe operator (Chapter 2)
- Higher-order functions (Chapter 3)
- Streams (Chapter 3)
- Data transformation mindset (Chapters 2 & 3)

**Task:** Process a CSV file of sales data:

```elixir
defmodule SalesAnalyzer do
  # Sample CSV format:
  # date,product,quantity,price
  # 2023-01-15,Laptop,2,999.00
  # 2023-01-16,Mouse,5,25.00

  def analyze(file_path) do
    file_path
    |> File.stream!()
    |> Stream.drop(1)  # Skip header
    |> Stream.map(&parse_line/1)
    |> Stream.filter(&valid_sale?/1)
    |> Enum.reduce(%{}, &aggregate_sales/2)
    |> format_report()
  end

  defp parse_line(line) do
    # Parse CSV line to map
    # Return {:ok, sale_map} or {:error, reason}
  end

  defp valid_sale?({:ok, _}), do: true
  defp valid_sale?(_), do: false

  defp aggregate_sales({:ok, sale}, acc) do
    # Aggregate by product: %{product => {total_quantity, total_revenue}}
  end

  defp format_report(aggregates) do
    # Format as readable report
  end
end
```

**Success Criteria:**
- File processed line-by-line (streaming)
- Pattern matching on success/error tuples
- Proper use of pipe operator
- Clear data transformation steps

---

### Exercise 4: Recursive Data Structure Navigation

**Objective:** Navigate and transform nested data structures using recursion and pattern matching.

**Concepts Reinforced:**
- Maps and nested structures (Chapter 2)
- Pattern matching (Chapter 3)
- Recursion (Chapter 3)
- Immutability (Chapter 2)

**Task:** Build a JSON-like data structure navigator:

```elixir
defmodule DataNavigator do
  # Navigate nested maps/lists using a path
  # get_in(data, ["user", "address", "city"])
  # Should work with maps and lists

  def get_in(data, []), do: data
  def get_in(data, [key | rest]) when is_map(data) do
    # Handle map navigation
  end
  def get_in(data, [index | rest]) when is_list(data) and is_integer(index) do
    # Handle list navigation
  end

  # Update nested value
  def put_in(data, path, value) do
    # Immutably update value at path
  end

  # Apply function to all values at any depth
  def map_values(data, fun) when is_map(data) do
    # Recursively apply fun to all map values
  end
  def map_values(data, fun) when is_list(data) do
    # Recursively apply to list elements
  end
  def map_values(data, fun) do
    fun.(data)
  end
end
```

**Example Usage:**
```elixir
data = %{
  user: %{
    name: "Alice",
    addresses: [
      %{city: "Portland", zip: "97201"},
      %{city: "Seattle", zip: "98101"}
    ]
  }
}

DataNavigator.get_in(data, [:user, :addresses, 1, :city])  # => "Seattle"
DataNavigator.put_in(data, [:user, :name], "Bob")  # => updated structure
DataNavigator.map_values(data, fn v when is_binary(v) -> String.upcase(v); v -> v end)
```

---

### Exercise 5: FizzBuzz Variations

**Objective:** Implement FizzBuzz variations using different control flow techniques.

**Concepts Reinforced:**
- Multiclause functions (Chapter 3)
- Guards (Chapter 3)
- Comprehensions (Chapter 3)
- Functions as first-class values (Chapter 2)

**Task:** Implement FizzBuzz four different ways:

```elixir
defmodule FizzBuzzVariations do
  # 1. Using multiclause functions with guards
  def multiclause(n) when is_integer(n) and n > 0 do
    Enum.map(1..n, &fizzbuzz_clause/1)
  end

  defp fizzbuzz_clause(n) when rem(n, 15) == 0, do: # ...
  defp fizzbuzz_clause(n) when # ... complete the clauses

  # 2. Using case
  def with_case(n) do
    Enum.map(1..n, fn x ->
      case {rem(x, 3), rem(x, 5)} do
        {0, 0} -> # ...
        # Complete the cases
      end
    end)
  end

  # 3. Using cond
  def with_cond(n) do
    # Your implementation
  end

  # 4. Using comprehension with pattern matching
  def with_comprehension(n) do
    for x <- 1..n do
      # Use pattern matching or guards here
    end
  end

  # Compare the approaches
  def compare(n) do
    [:multiclause, :with_case, :with_cond, :with_comprehension]
    |> Enum.map(fn approach ->
      result = apply(__MODULE__, approach, [n])
      {approach, result}
    end)
    |> Enum.all?(fn {_approach, result} -> result == hd(result) end)
  end
end
```

**Success Criteria:**
- All four implementations produce identical results
- Understanding trade-offs of each approach
- Proper use of pattern matching in each style

---

## Capstone Project: Log File Analyzer with Pattern Matching

### Project Description

Build a comprehensive log file analyzer that parses, filters, and generates reports from server log files. This project demonstrates pattern matching, recursion, streams, and all the control flow techniques from Chapter 3.

### Scenario

You're building a log analysis tool for a web server. Log files contain entries in various formats:

```
[2023-11-15 10:23:45] INFO User login: user_id=123, ip=192.168.1.1
[2023-11-15 10:24:12] ERROR Database connection failed: timeout after 30s
[2023-11-15 10:24:15] WARN High memory usage: 85%
[2023-11-15 10:25:01] INFO API request: GET /api/users - 200 - 45ms
[2023-11-15 10:25:03] ERROR API request: POST /api/orders - 500 - error: invalid payload
```

### Requirements

#### 1. Core Module: `LogAnalyzer`

**Log Entry Parsing:**
```elixir
defmodule LogAnalyzer do
  # Parse a log line into a structured map
  # Returns {:ok, entry} or {:error, reason}
  def parse_line(line) do
    # Use pattern matching on the string
    # Extract: timestamp, level, message
  end
end

defmodule LogAnalyzer.Entry do
  defstruct [:timestamp, :level, :message, :metadata]

  # Pattern match on different log levels
  def create({:ok, {timestamp, level, message}}) do
    %__MODULE__{
      timestamp: parse_timestamp(timestamp),
      level: parse_level(level),
      message: message,
      metadata: extract_metadata(message)
    }
  end

  # Different parsers for different log levels
  defp extract_metadata(message) do
    # Use pattern matching to extract metadata
    # e.g., user_id, ip, status_code, response_time
  end
end
```

**Required Functions:**

```elixir
# Filter logs by level using multiclause functions
def filter_by_level(entries, :error), do: # ...
def filter_by_level(entries, :warn), do: # ...
def filter_by_level(entries, :info), do: # ...

# Find patterns using recursion
def find_pattern(entries, pattern) do
  # Recursively search for pattern in messages
end

# Aggregate statistics using Enum.reduce
def statistics(entries) do
  entries
  |> Enum.reduce(%{}, fn entry, acc ->
    # Accumulate counts by level, errors by type, etc.
  end)
end

# Stream processing for large files
def analyze_file!(path) do
  path
  |> File.stream!()
  |> Stream.map(&parse_line/1)
  |> Stream.filter(&valid_entry?/1)
  # Continue processing
end
```

#### 2. Pattern Matching Module: `LogAnalyzer.Patterns`

```elixir
defmodule LogAnalyzer.Patterns do
  # Pattern match on different message types
  def categorize_message("User login" <> rest), do: {:user_action, :login, parse_user_info(rest)}
  def categorize_message("User logout" <> rest), do: {:user_action, :logout, parse_user_info(rest)}
  def categorize_message("API request: " <> rest), do: {:api_call, parse_api_info(rest)}
  def categorize_message("Database" <> rest), do: {:database, parse_db_info(rest)}
  def categorize_message(_), do: {:unknown, nil}

  # Recursive pattern finder
  def find_error_sequences(entries) do
    # Find sequences where errors occur close together
    # Use recursion with accumulator
  end

  # Pattern matching on entry structures
  def critical?(entry) do
    case entry do
      %{level: :error, message: "Database" <> _} -> true
      %{level: :error, metadata: %{status_code: code}} when code >= 500 -> true
      _ -> false
    end
  end
end
```

#### 3. Report Generator Module: `LogAnalyzer.Reporter`

```elixir
defmodule LogAnalyzer.Reporter do
  # Use comprehensions to generate reports
  def error_summary(entries) do
    for entry <- entries,
        entry.level == :error,
        into: %{} do
      {extract_error_type(entry), count_or_increment(entry)}
    end
  end

  # Use Enum functions for aggregation
  def timeline_report(entries) do
    entries
    |> Enum.group_by(&extract_hour/1)
    |> Enum.map(fn {hour, entries} ->
      %{
        hour: hour,
        total: length(entries),
        by_level: count_by_level(entries)
      }
    end)
    |> Enum.sort_by(& &1.hour)
  end

  # Use streams for memory-efficient reporting
  def generate_large_report!(input_path, output_path) do
    input_path
    |> File.stream!()
    |> Stream.map(&parse_and_analyze/1)
    |> Stream.filter(&include_in_report?/1)
    |> Stream.map(&format_report_line/1)
    |> Enum.into(File.stream!(output_path))
  end
end
```

#### 4. Query Module: `LogAnalyzer.Query`

```elixir
defmodule LogAnalyzer.Query do
  # Use with expression for complex queries
  def find_user_session(entries, user_id) do
    with {:ok, login} <- find_login(entries, user_id),
         {:ok, actions} <- find_actions_after(entries, login),
         {:ok, logout} <- find_logout(entries, user_id, login) do
      {:ok, %{login: login, actions: actions, logout: logout}}
    else
      {:error, :no_login} -> {:error, "User never logged in"}
      {:error, :no_logout} -> {:error, "Session still active"}
      error -> error
    end
  end

  # Recursive time window analysis
  def analyze_time_window(entries, start_time, end_time) do
    # Recursively filter and analyze entries in time window
  end
end
```

### Technical Requirements

1. **Pattern Matching:**
   - Parse log lines using string pattern matching
   - Match on different log entry structures
   - Use guards to refine matches
   - Handle malformed entries gracefully

2. **Multiclause Functions:**
   - Different handlers for different log levels
   - Pattern-based message categorization
   - Multiple report formats

3. **Recursion:**
   - Recursive list processing for patterns
   - Tail-recursive aggregations
   - Recursive time window analysis

4. **Higher-Order Functions:**
   - Use Enum.map, filter, reduce extensively
   - Custom reducer functions
   - Function composition for pipelines

5. **Streams:**
   - Process large log files without loading into memory
   - Lazy transformations
   - Efficient filtering and mapping

6. **Comprehensions:**
   - Generate summary reports
   - Cross-reference different log types
   - Build lookup structures

### Deliverables

1. **Source Files:**
   - `log_analyzer.ex` - Core parsing and analysis
   - `log_analyzer/entry.ex` - Entry struct and functions
   - `log_analyzer/patterns.ex` - Pattern matching logic
   - `log_analyzer/reporter.ex` - Report generation
   - `log_analyzer/query.ex` - Query interface

2. **Sample Log Files:**
   - `sample_small.log` - 100 lines for testing
   - `sample_large.log` - 10,000+ lines for performance testing
   - Include various error types and patterns

3. **Demo Script:**
   - `demo.exs` - Demonstrates all functionality
   - Show parsing, filtering, pattern finding
   - Generate multiple report types
   - Compare recursive vs. Enum vs. Stream approaches

4. **Test File:**
   - `log_analyzer_test.exs` - ExUnit tests
   - Test pattern matching edge cases
   - Test recursion base cases
   - Test stream processing

### Example Usage

```elixir
# Parse and analyze a log file
{:ok, analysis} = LogAnalyzer.analyze_file!("server.log")

# Filter errors
errors = LogAnalyzer.filter_by_level(analysis.entries, :error)

# Find patterns
critical = LogAnalyzer.Patterns.find_error_sequences(errors)

# Generate reports
timeline = LogAnalyzer.Reporter.timeline_report(analysis.entries)
summary = LogAnalyzer.Reporter.error_summary(errors)

# Complex queries
{:ok, session} = LogAnalyzer.Query.find_user_session(analysis.entries, 123)

# Stream processing for large files
LogAnalyzer.Reporter.generate_large_report!(
  "huge_log.log",
  "summary_report.txt"
)
```

### Bonus Challenges

1. **Real-Time Analysis:**
   - Use Stream.resource/3 to tail a log file
   - Detect patterns as they occur
   - Trigger alerts for critical patterns

2. **Performance Comparison:**
   - Implement the same analysis with:
     - Pure recursion
     - Enum functions
     - Stream functions
   - Measure memory and time for each
   - Write a report comparing approaches

3. **Advanced Pattern Detection:**
   - Detect distributed traces (multi-line patterns)
   - Find correlation between events
   - Use recursion with lookahead

4. **Query Language:**
   - Build a mini query DSL
   - Example: `query("level:error AND message:contains(database) AND timestamp:last(1h)")`
   - Parse and execute queries using pattern matching

5. **Visualization:**
   - Generate ASCII charts of timeline data
   - Use comprehensions to build chart structures
   - Example: horizontal bar chart of errors per hour

### Evaluation Criteria

**Pattern Matching Mastery (30 points)**
- Elegant string and data structure matching (10 pts)
- Proper use of guards (5 pts)
- Handling edge cases and malformed data (10 pts)
- Multiple clause functions well-organized (5 pts)

**Control Flow Techniques (30 points)**
- Effective use of multiclause functions (10 pts)
- Proper recursion (base cases, tail calls) (10 pts)
- Appropriate choice of if/case/cond/with (5 pts)
- Clean control flow logic (5 pts)

**Functional Iteration (25 points)**
- Effective use of Enum functions (8 pts)
- Proper stream usage for large files (8 pts)
- Good comprehensions where appropriate (5 pts)
- Understanding of lazy vs. eager (4 pts)

**Code Quality (15 points)**
- Clear, readable code (5 pts)
- Good function decomposition (5 pts)
- Appropriate use of private functions (3 pts)
- Consistent style (2 pts)

### Tips for Success

1. **Start Small:** Begin with parsing a single log line, then build up
2. **Test Patterns:** Use iex to test pattern matches interactively
3. **Think Recursively:** Draw out the recursive cases before coding
4. **Choose Tools Wisely:** Use Enum for small data, Stream for large files
5. **Pattern Match Early:** Let pattern matching do the work instead of if/else chains
6. **Use Guards:** Guards make your intent clearer than separate functions
7. **Tail Recursion:** For large datasets, ensure your recursion is tail-optimized
8. **Comprehensions:** Great for transforming and filtering, especially with multiple sources

### Connection to Previous Chapters

This project reinforces:

**From Chapter 1:**
- Thinking about scalability (streaming large files)
- Fault tolerance (handling malformed entries)
- System design (modular analyzer components)

**From Chapter 2:**
- Maps and structs for data (log entries)
- Module organization (multiple related modules)
- String operations (parsing log lines)
- Pipe operator (data transformation pipelines)

**From Chapter 3:**
- Pattern matching everywhere
- Multiclause functions for different cases
- Recursion for list processing
- Higher-order functions for elegance
- Streams for efficiency

---

## Additional Practice

### Quick Challenges

1. **Pattern Matching Katas:**
   - Parse different date formats using pattern matching
   - Extract structured data from formatted strings
   - Match on complex nested structures

2. **Recursion Practice:**
   - Implement tree traversal (depth-first, breadth-first)
   - Recursive fibonacci with memoization
   - Recursive flatten for arbitrarily nested lists

3. **Stream Experiments:**
   - Create infinite streams (fibonacci, primes)
   - Process large CSV files
   - Real-time data processing simulation

4. **Comprehension Challenges:**
   - Generate permutations and combinations
   - Sudoku solver using comprehensions
   - Cross-join multiple enumerables

### Debugging Exercises

Identify and fix the errors in these code snippets:

```elixir
# Exercise 1: What's wrong with this pattern match?
defmodule Broken1 do
  def process({:ok, value}) do
    value * 2
  end

  def process(error) do
    error
  end
end

# Exercise 2: Why does this recursion fail?
defmodule Broken2 do
  def sum_list([head | tail]) do
    head + sum_list(tail)
  end
end

# Exercise 3: What's the issue here?
defmodule Broken3 do
  def factorial(0), do: 1
  def factorial(n), do: n * factorial(n)
end

# Exercise 4: Why is this not tail recursive?
defmodule Broken4 do
  def length(list, acc \\ 0)
  def length([], acc), do: acc
  def length([_ | tail], acc) do
    length(tail, acc + 1) + 0
  end
end
```

---

## Success Checklist

Before moving to Chapter 4, ensure you can:

- [ ] Use the match operator (=) for pattern matching
- [ ] Destructure tuples, lists, and maps with pattern matching
- [ ] Understand when matches succeed vs. fail
- [ ] Use the pin operator (^) to match against variable values
- [ ] Write multiclause functions with pattern matching
- [ ] Use guards to refine patterns with conditions
- [ ] Know which functions/operators are allowed in guards
- [ ] Understand clause ordering importance
- [ ] Use if, unless, cond, and case appropriately
- [ ] Chain validations with the with expression
- [ ] Write recursive functions with proper base cases
- [ ] Convert recursion to tail-recursive form
- [ ] Understand tail-call optimization
- [ ] Use Enum.map, filter, reduce effectively
- [ ] Write higher-order functions
- [ ] Use comprehensions for filtering and transformation
- [ ] Understand when to use Stream vs. Enum
- [ ] Create and consume infinite streams
- [ ] Compose multiple transformations with streams

---

## Looking Ahead

Chapter 4 will cover:
- Protocols (polymorphism in Elixir)
- Data abstractions
- Implementing protocols for custom types
- Built-in protocols (Enumerable, Collectable, Inspect)

The pattern matching and functional programming skills from Chapter 3 are essential for understanding how protocols enable polymorphic behavior across different data types!
