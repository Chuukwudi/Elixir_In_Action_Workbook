# Chapter 4: Data Abstractions - Learning Exercises

## Chapter Summary

Chapter 4 introduces data abstractions in Elixir through modules and pure functions, replacing object-oriented classes with stateless modules that expose functions for creating, manipulating, and querying data structures. The chapter demonstrates how to build abstractions using maps and structs, emphasizing that while Elixir data is transparent (always visible), modules provide the interface layer that clients should use rather than relying on internal structure. Protocols enable polymorphism by defining contracts that different data types can implement, allowing generic code like Enum to work across various structures through a common interface defined by protocols like Enumerable and Collectable.

---

## Concept Drills

These exercises focus on understanding the fundamental concepts introduced in Chapter 4.

### Drill 1: Module-Based Abstractions

**Objective:** Understand how modules abstract data operations in Elixir.

**Task:** Create a `Temperature` abstraction that works with temperatures in different units:

```elixir
defmodule Temperature do
  # Temperature is stored internally as Kelvin (your choice of representation)

  # Create a new temperature from Celsius
  def from_celsius(degrees) do
    # Your implementation
  end

  # Create a new temperature from Fahrenheit
  def from_fahrenheit(degrees) do
    # Your implementation
  end

  # Convert to Celsius
  def to_celsius(temp) do
    # Your implementation
  end

  # Convert to Fahrenheit
  def to_fahrenheit(temp) do
    # Your implementation
  end

  # Compare two temperatures
  def warmer?(temp1, temp2) do
    # Your implementation
  end
end
```

**Expected Usage:**
```elixir
temp1 = Temperature.from_celsius(25)
temp2 = Temperature.from_fahrenheit(80)

Temperature.to_celsius(temp1)     # => 25
Temperature.to_fahrenheit(temp2)  # => 80
Temperature.warmer?(temp2, temp1) # => true
```

**Success Criteria:**
- Internal representation is hidden from clients
- All conversions are accurate
- Functions are pipe-friendly (first argument is the abstraction)
- Clients never manipulate the internal structure directly

---

### Drill 2: Composing Abstractions

**Objective:** Build one abstraction on top of another.

**Task:** Create a `Stack` abstraction using a list internally, then build a `BrowserHistory` on top of it:

```elixir
defmodule Stack do
  def new, do: # Your implementation
  def push(stack, item), do: # Your implementation
  def pop(stack), do: # Your implementation (returns {item, new_stack} or {:error, :empty})
  def peek(stack), do: # Your implementation (returns {:ok, item} or {:error, :empty})
  def empty?(stack), do: # Your implementation
end

defmodule BrowserHistory do
  # Uses Stack internally
  # Tracks visited URLs and allows back/forward navigation

  def new, do: # Your implementation
  def visit(history, url), do: # Your implementation
  def back(history), do: # Your implementation (returns {url, new_history} or error)
  def current(history), do: # Your implementation
end
```

**Expected Usage:**
```elixir
history = BrowserHistory.new()
|> BrowserHistory.visit("google.com")
|> BrowserHistory.visit("github.com")
|> BrowserHistory.visit("stackoverflow.com")

{url, history} = BrowserHistory.back(history)
# url => "github.com"

BrowserHistory.current(history)
# => "github.com"
```

**Success Criteria:**
- Stack is a complete, reusable abstraction
- BrowserHistory delegates to Stack
- Separation of concerns is clear
- Both abstractions have clean interfaces

---

### Drill 3: Maps for Structured Data

**Objective:** Use maps to represent structured entities with multiple fields.

**Task:** Represent a book catalog system using maps:

```elixir
defmodule BookCatalog do
  # A book is represented as: %{title: ..., author: ..., isbn: ..., year: ...}

  def new, do: # Empty catalog (what data structure?)

  def add_book(catalog, book) do
    # Add book to catalog, use ISBN as key
  end

  def find_by_isbn(catalog, isbn), do: # {:ok, book} or {:error, :not_found}

  def find_by_author(catalog, author_name), do: # List of books

  def update_book(catalog, isbn, updater_fn), do: # Updated catalog

  def books_in_year(catalog, year), do: # List of books
end
```

**Test Cases:**
```elixir
catalog = BookCatalog.new()
|> BookCatalog.add_book(%{
  title: "Elixir in Action",
  author: "Saša Jurić",
  isbn: "978-1617295027",
  year: 2019
})
|> BookCatalog.add_book(%{
  title: "Programming Elixir",
  author: "Dave Thomas",
  isbn: "978-1680502992",
  year: 2018
})

BookCatalog.find_by_isbn(catalog, "978-1617295027")
# => {:ok, %{title: "Elixir in Action", ...}}

BookCatalog.find_by_author(catalog, "Dave Thomas")
# => [%{title: "Programming Elixir", ...}]
```

---

### Drill 4: Defining and Using Structs

**Objective:** Create structs for type-safe data abstractions.

**Task:** Implement a `Money` abstraction using structs:

```elixir
defmodule Money do
  defstruct amount: 0, currency: :USD

  def new(amount, currency \\ :USD) do
    # Create new Money struct
    # Validate that amount is a number
  end

  def add(%Money{currency: c1} = m1, %Money{currency: c2} = m2) do
    # Can only add same currency
    # Return {:ok, money} or {:error, :currency_mismatch}
  end

  def multiply(%Money{} = money, factor) do
    # Multiply amount by factor
  end

  def format(%Money{} = money) do
    # Format as string: "$10.50" or "€20.00"
  end
end
```

**Expected Output:**
```elixir
m1 = Money.new(10.50, :USD)
m2 = Money.new(5.25, :USD)
m3 = Money.new(15, :EUR)

{:ok, total} = Money.add(m1, m2)
# => %Money{amount: 15.75, currency: :USD}

Money.add(m1, m3)
# => {:error, :currency_mismatch}

Money.format(m1)
# => "$10.50"
```

**Success Criteria:**
- Struct definition with default values
- Pattern matching on struct type in function heads
- Type checking enforced by pattern matching
- Proper error handling for invalid operations

---

### Drill 5: Pattern Matching on Structs

**Objective:** Use pattern matching to destructure and validate structs.

**Task:** Create a `Rectangle` and `Circle` struct and pattern match in functions:

```elixir
defmodule Rectangle do
  defstruct width: 0, height: 0

  def new(width, height), do: %Rectangle{width: width, height: height}
end

defmodule Circle do
  defstruct radius: 0

  def new(radius), do: %Circle{radius: radius}
end

defmodule Geometry do
  # Pattern match on struct types
  def area(%Rectangle{width: w, height: h}) do
    # Calculate area
  end

  def area(%Circle{radius: r}) do
    # Calculate area
  end

  def perimeter(%Rectangle{width: w, height: h}) do
    # Calculate perimeter
  end

  def perimeter(%Circle{radius: r}) do
    # Calculate circumference
  end

  # Takes either shape
  def scale(shape, factor) do
    case shape do
      %Rectangle{} = r -> # Scale rectangle
      %Circle{} = c -> # Scale circle
    end
  end
end
```

**Success Criteria:**
- Pattern matching extracts struct fields
- Functions are polymorphic through pattern matching
- Type safety: passing wrong struct type raises error
- Understanding that structs are specialized maps

---

### Drill 6: Hierarchical Data Updates

**Objective:** Update nested immutable data structures.

**Task:** Given this nested structure, perform immutable updates:

```elixir
company = %{
  name: "Tech Corp",
  employees: %{
    1 => %{name: "Alice", salary: 50000, department: "Engineering"},
    2 => %{name: "Bob", salary: 60000, department: "Sales"},
    3 => %{name: "Charlie", salary: 55000, department: "Engineering"}
  }
}
```

Write functions that:
1. Give all employees a 10% raise
2. Change an employee's department
3. Add a new employee
4. Remove an employee

```elixir
defmodule Company do
  def give_raises(company, percentage) do
    # Update all employee salaries
  end

  def transfer_employee(company, id, new_department) do
    # Change employee department
  end

  def hire(company, id, employee_data) do
    # Add new employee
  end

  def fire(company, id) do
    # Remove employee
  end
end
```

Also demonstrate using `put_in/2`, `update_in/2`, and `get_in/2`:

```elixir
# Update Bob's salary using put_in
put_in(company, [:employees, 2, :salary], 65000)

# Give Bob a raise using update_in
update_in(company, [:employees, 2, :salary], &(&1 * 1.1))

# Get Alice's department
get_in(company, [:employees, 1, :department])
```

---

### Drill 7: Iterative Construction

**Objective:** Build data structures iteratively using `Enum.reduce`.

**Task:** Build a shopping cart from a list of items:

```elixir
defmodule ShoppingCart do
  defstruct items: %{}, total: 0.0

  def new, do: %ShoppingCart{}

  # Add single item
  def add_item(cart, item_id, price, quantity \\ 1) do
    # Update items map and total
  end

  # Build from list of {item_id, price, quantity} tuples
  def new(items_list) when is_list(items_list) do
    # Use Enum.reduce to build cart from list
    Enum.reduce(items_list, new(), fn {id, price, qty}, cart ->
      add_item(cart, id, price, qty)
    end)
  end

  def remove_item(cart, item_id) do
    # Remove item and update total
  end

  def item_count(cart) do
    # Total number of items (considering quantities)
  end
end
```

**Expected Usage:**
```elixir
items = [
  {"apple", 1.50, 3},
  {"banana", 0.75, 5},
  {"orange", 2.00, 2}
]

cart = ShoppingCart.new(items)
# => %ShoppingCart{items: %{...}, total: 12.25}
```

---

### Drill 8: Protocol Basics

**Objective:** Understand how protocols enable polymorphism.

**Task:** Implement the `String.Chars` protocol for custom types:

```elixir
defmodule User do
  defstruct name: "", email: ""
end

defmodule Product do
  defstruct name: "", price: 0
end

# Implement String.Chars for User
defimpl String.Chars, for: User do
  def to_string(user) do
    # Format as "Name <email>"
  end
end

# Implement String.Chars for Product
defimpl String.Chars, for: Product do
  def to_string(product) do
    # Format as "Product: Name - $Price"
  end
end
```

**Test:**
```elixir
user = %User{name: "Alice", email: "alice@example.com"}
product = %Product{name: "Laptop", price: 999}

IO.puts(user)    # => "Alice <alice@example.com>"
IO.puts(product) # => "Product: Laptop - $999"

# Also works with to_string/1
to_string(user)    # => "Alice <alice@example.com>"
to_string(product) # => "Product: Laptop - $999"
```

**Success Criteria:**
- Protocol implementation is separate from struct definition
- Both types can be passed to `IO.puts/1`
- `to_string/1` works for both types
- Understanding that this is runtime polymorphism

---

### Drill 9: Enumerable Protocol

**Objective:** Make custom data structures work with `Enum` functions.

**Task:** Create a `Range` struct (simplified version) and make it enumerable:

```elixir
defmodule SimpleRange do
  defstruct first: 0, last: 0

  def new(first, last), do: %SimpleRange{first: first, last: last}
end

# Implement Enumerable protocol
defimpl Enumerable, for: SimpleRange do
  def count(%SimpleRange{first: first, last: last}) do
    {:ok, last - first + 1}
  end

  def member?(%SimpleRange{first: first, last: last}, value) do
    {:ok, value >= first and value <= last}
  end

  def slice(%SimpleRange{} = range) do
    # This is more complex - return :error for simplicity
    # or implement for bonus points
    {:error, __MODULE__}
  end

  def reduce(%SimpleRange{first: first, last: last}, acc, fun) do
    # This is the key function - implement reduction
    do_reduce(first, last, acc, fun)
  end

  defp do_reduce(_current, _last, {:halt, acc}, _fun), do: {:halted, acc}
  defp do_reduce(current, last, {:suspend, acc}, fun), do: {:suspended, acc, &do_reduce(current, last, &1, fun)}
  defp do_reduce(current, last, {:cont, acc}, fun) when current <= last do
    do_reduce(current + 1, last, fun.(current, acc), fun)
  end
  defp do_reduce(_current, _last, {:cont, acc}, _fun), do: {:done, acc}
end
```

**Test:**
```elixir
range = SimpleRange.new(1, 5)

Enum.to_list(range)
# => [1, 2, 3, 4, 5]

Enum.map(range, fn x -> x * 2 end)
# => [2, 4, 6, 8, 10]

Enum.filter(range, fn x -> rem(x, 2) == 0 end)
# => [2, 4]

Enum.reduce(range, 0, &+/2)
# => 15
```

---

## Integration Exercises

These exercises combine concepts from Chapter 4 with concepts from previous chapters.

### Exercise 1: Enhanced TodoList with Structs

**Objective:** Refactor the TodoList to use proper structs and demonstrate hierarchical updates.

**Concepts Reinforced:**
- Structs (Chapter 4)
- Pattern matching (Chapter 3)
- Immutable updates (Chapters 2 & 4)
- Module abstractions (Chapter 4)

**Task:** Implement a complete TodoList using structs for both the list and entries:

```elixir
defmodule TodoList.Entry do
  defstruct id: nil, date: nil, title: "", priority: :normal, completed: false

  def new(date, title, priority \\ :normal) do
    # Create entry (id will be set by TodoList)
  end
end

defmodule TodoList do
  defstruct entries: %{}, next_id: 1

  def new(entries \\ []) do
    # Build TodoList from list of entries
  end

  def add_entry(todo_list, entry) do
    # Add entry with auto-generated ID
  end

  def entries(todo_list, date) do
    # Return all entries for date
  end

  def update_entry(todo_list, entry_id, updater_fn) do
    # Update entry using hierarchical update
  end

  def delete_entry(todo_list, entry_id) do
    # Remove entry
  end

  def mark_completed(todo_list, entry_id) do
    # Set entry's completed field to true
  end

  def filter_by_priority(todo_list, priority) do
    # Return all entries with given priority
  end

  def pending_entries(todo_list) do
    # Return all incomplete entries
  end
end
```

**Success Criteria:**
- Both TodoList and Entry are proper structs
- Pattern matching on structs in function heads
- Immutable hierarchical updates
- All CRUD operations work correctly
- Additional filtering/query functions

---

### Exercise 2: Multi-Currency Money System

**Objective:** Build a money abstraction with currency conversion using protocols.

**Concepts Reinforced:**
- Structs (Chapter 4)
- Protocols (Chapter 4)
- Pattern matching and guards (Chapter 3)
- Error handling with tagged tuples (Chapter 2)

**Task:**

```elixir
defmodule Money do
  defstruct [:amount, :currency]

  def new(amount, currency) when is_number(amount) do
    # Validate amount and currency
  end

  def add(%Money{currency: c} = m1, %Money{currency: c} = m2) do
    # Same currency - direct addition
  end

  def add(%Money{} = m1, %Money{} = m2) do
    {:error, :currency_mismatch}
  end

  def convert(%Money{} = money, target_currency, exchange_rates) do
    # Convert using exchange rates map
    # exchange_rates example: %{{:USD, :EUR} => 0.85, {:EUR, :USD} => 1.18}
  end

  # Implement Inspect protocol for nice output
  defimpl Inspect do
    def inspect(%Money{amount: amount, currency: currency}, _opts) do
      # Format nicely
    end
  end

  # Implement String.Chars protocol
  defimpl String.Chars do
    def to_string(%Money{amount: amount, currency: currency}) do
      # Format as "$10.50", "€20.00", etc.
    end
  end
end

defmodule Wallet do
  # Contains multiple Money values in different currencies
  defstruct balances: %{}

  def new, do: %Wallet{}

  def add_money(wallet, %Money{currency: currency} = money) do
    # Add to balance for that currency
  end

  def total_in_currency(wallet, target_currency, exchange_rates) do
    # Convert all balances and sum
  end

  def can_afford?(wallet, %Money{} = price, exchange_rates) do
    # Check if wallet has enough
  end
end
```

**Success Criteria:**
- Money struct with validation
- Currency conversion logic
- Protocol implementations for nice printing
- Wallet manages multiple currencies
- Proper error handling
- Pattern matching on currency

---

### Exercise 3: Inventory System with Protocols

**Objective:** Build an inventory system where different item types implement common protocols.

**Concepts Reinforced:**
- Multiple structs (Chapter 4)
- Protocol polymorphism (Chapter 4)
- Enum operations (Chapter 3)
- Module composition (Chapter 4)

**Task:** Create different product types that all implement common protocols:

```elixir
# Define protocol for items
defprotocol Valuable do
  @doc "Returns the value of the item"
  def value(item)
end

defprotocol Stackable do
  @doc "Returns true if items can be stacked"
  def stackable?(item)

  @doc "Returns maximum stack size"
  def max_stack(item)
end

defmodule Item.Weapon do
  defstruct name: "", damage: 0, rarity: :common, durability: 100
end

defmodule Item.Potion do
  defstruct name: "", healing: 0, rarity: :common
end

defmodule Item.Material do
  defstruct name: "", category: :misc, rarity: :common
end

# Implement protocols for each type
defimpl Valuable, for: Item.Weapon do
  def value(%{rarity: :common}), do: 10
  def value(%{rarity: :rare}), do: 100
  def value(%{rarity: :epic}), do: 1000
end

defimpl Valuable, for: Item.Potion do
  def value(%{healing: h}) do
    h * 2
  end
end

defimpl Valuable, for: Item.Material do
  # Your implementation
end

defimpl Stackable, for: Item.Weapon do
  def stackable?(_), do: false
  def max_stack(_), do: 1
end

defimpl Stackable, for: Item.Potion do
  # Potions can stack
  def stackable?(_), do: true
  def max_stack(_), do: 99
end

defimpl Stackable, for: Item.Material do
  # Materials can stack
end

# Inventory module
defmodule Inventory do
  defstruct items: [], max_weight: 100

  def new(max_weight \\ 100), do: %Inventory{max_weight: max_weight}

  def add_item(inventory, item) do
    # Add item, respecting stacking rules
    # Use Stackable protocol
  end

  def total_value(inventory) do
    # Sum values using Valuable protocol
    inventory.items
    |> Enum.map(&Valuable.value/1)
    |> Enum.sum()
  end

  def find_stackable(inventory) do
    # Find all stackable items
    Enum.filter(inventory.items, &Stackable.stackable?/1)
  end

  def sort_by_value(inventory) do
    # Sort items by value
  end
end
```

**Success Criteria:**
- Multiple struct types
- Protocols implemented differently for each type
- Inventory uses protocols generically
- Understanding of protocol dispatch
- Can add new item types without changing Inventory

---

### Exercise 4: Graph Data Structure with Protocols

**Objective:** Build a graph abstraction and make it enumerable.

**Concepts Reinforced:**
- Complex data structures (Chapter 4)
- Enumerable protocol (Chapter 4)
- Recursion for traversal (Chapter 3)
- Pattern matching (Chapter 3)

**Task:**

```elixir
defmodule Graph do
  defstruct nodes: MapSet.new(), edges: %{}

  def new, do: %Graph{}

  def add_node(graph, node) do
    # Add node to graph
  end

  def add_edge(graph, from, to) do
    # Add directed edge
  end

  def neighbors(graph, node) do
    # Return all nodes reachable from this node
  end

  # Depth-first traversal
  def dfs(graph, start) do
    do_dfs(graph, start, MapSet.new(), [])
  end

  defp do_dfs(graph, node, visited, acc) do
    # Recursive DFS implementation
  end
end

# Make graph enumerable (traverses nodes in DFS order)
defimpl Enumerable, for: Graph do
  def count(%Graph{nodes: nodes}) do
    {:ok, MapSet.size(nodes)}
  end

  def member?(%Graph{nodes: nodes}, node) do
    {:ok, MapSet.member?(nodes, node)}
  end

  def slice(_graph) do
    {:error, __MODULE__}
  end

  def reduce(%Graph{nodes: nodes}, acc, fun) do
    # Implement reduction over nodes
    Enumerable.reduce(MapSet.to_list(nodes), acc, fun)
  end
end

defimpl String.Chars, for: Graph do
  def to_string(%Graph{nodes: nodes, edges: edges}) do
    # Format graph nicely
    node_count = MapSet.size(nodes)
    edge_count = Enum.sum(Enum.map(edges, fn {_, neighbors} -> MapSet.size(neighbors) end))
    "Graph(#{node_count} nodes, #{edge_count} edges)"
  end
end
```

**Example Usage:**
```elixir
graph = Graph.new()
|> Graph.add_node(:a)
|> Graph.add_node(:b)
|> Graph.add_node(:c)
|> Graph.add_edge(:a, :b)
|> Graph.add_edge(:b, :c)
|> Graph.add_edge(:a, :c)

# Uses Enumerable protocol
Enum.to_list(graph)
# => [:a, :b, :c]

Enum.member?(graph, :b)
# => true

# DFS traversal
Graph.dfs(graph, :a)
# => [:a, :b, :c]
```

---

### Exercise 5: CSV Import/Export with Multiple Formats

**Objective:** Combine streaming, protocols, and data abstraction for file I/O.

**Concepts Reinforced:**
- Streams (Chapter 3)
- Protocols (Chapter 4)
- Iterative construction (Chapter 4)
- Data transformation pipelines (Chapters 2 & 3)

**Task:**

```elixir
# Protocol for CSV serialization
defprotocol CSVSerializable do
  @doc "Converts the struct to a CSV row"
  def to_csv_row(data)

  @doc "Returns CSV headers"
  def headers(data)
end

defmodule Contact do
  defstruct [:id, :name, :email, :phone]

  def new(id, name, email, phone) do
    %Contact{id: id, name: name, email: email, phone: phone}
  end
end

defimpl CSVSerializable, for: Contact do
  def to_csv_row(%Contact{id: id, name: name, email: email, phone: phone}) do
    "#{id},#{name},#{email},#{phone}"
  end

  def headers(_contact) do
    "id,name,email,phone"
  end
end

defmodule ContactList do
  defstruct contacts: %{}, next_id: 1

  def new, do: %ContactList{}

  def add_contact(list, contact) do
    # Add with auto-generated ID
  end

  # Import from CSV file
  def from_csv(file_path) do
    file_path
    |> File.stream!()
    |> Stream.drop(1)  # Skip header
    |> Stream.map(&parse_csv_line/1)
    |> Enum.reduce(new(), fn contact, list ->
      add_contact(list, contact)
    end)
  end

  defp parse_csv_line(line) do
    [id, name, email, phone] = String.split(String.trim(line), ",")
    Contact.new(String.to_integer(id), name, email, phone)
  end

  # Export to CSV file
  def to_csv(list, file_path) do
    file = File.open!(file_path, [:write])

    # Write header
    sample = hd(Map.values(list.contacts))
    IO.puts(file, CSVSerializable.headers(sample))

    # Write rows
    list.contacts
    |> Map.values()
    |> Enum.each(fn contact ->
      IO.puts(file, CSVSerializable.to_csv_row(contact))
    end)

    File.close(file)
  end
end
```

**Success Criteria:**
- Protocol enables different types to be serialized
- Streaming used for memory-efficient import
- Proper pipeline for data transformation
- Could add more types (Customer, Employee) that implement CSVSerializable

---

## Capstone Project: Library Management System

### Project Description

Build a comprehensive library management system demonstrating data abstractions, structs, protocols, and hierarchical data management. The system will manage books, members, loans, and provide various reports.

### Core Data Structures

```elixir
defmodule Library.Book do
  defstruct [
    :isbn,
    :title,
    :author,
    :year,
    :genre,
    :copies_total,
    :copies_available
  ]

  def new(isbn, title, author, year, genre, copies) do
    %Library.Book{
      isbn: isbn,
      title: title,
      author: author,
      year: year,
      genre: genre,
      copies_total: copies,
      copies_available: copies
    }
  end
end

defmodule Library.Member do
  defstruct [
    :id,
    :name,
    :email,
    :joined_date,
    :membership_type  # :basic, :premium
  ]
end

defmodule Library.Loan do
  defstruct [
    :id,
    :member_id,
    :isbn,
    :borrowed_date,
    :due_date,
    :returned_date  # nil if not returned
  ]
end

defmodule Library do
  defstruct [
    books: %{},        # isbn => Book
    members: %{},      # id => Member
    loans: %{},        # loan_id => Loan
    next_member_id: 1,
    next_loan_id: 1
  ]
end
```

### Required Functionality

#### 1. Core Operations Module

```elixir
defmodule Library.Operations do
  # Book management
  def add_book(library, book) do
    # Add or update book
  end

  def remove_book(library, isbn) do
    # Remove book if no active loans
  end

  def update_book(library, isbn, updater_fn) do
    # Update book details
  end

  # Member management
  def register_member(library, name, email, membership_type) do
    # Add new member with auto-generated ID
  end

  def update_member(library, member_id, updater_fn) do
    # Update member details
  end

  # Loan management
  def borrow_book(library, member_id, isbn) do
    # Create loan, decrease available copies
    # Check if copies available
    # Calculate due date based on membership type
    # {:ok, library} or {:error, reason}
  end

  def return_book(library, loan_id) do
    # Mark loan as returned, increase available copies
  end

  def extend_loan(library, loan_id, extra_days) do
    # Extend due date
  end
end
```

#### 2. Query Module

```elixir
defmodule Library.Query do
  # Book queries
  def search_books(library, term) do
    # Search by title or author
  end

  def books_by_genre(library, genre) do
    # All books in genre
  end

  def available_books(library) do
    # Books with available copies
  end

  # Member queries
  def member_loans(library, member_id) do
    # All loans (active and returned) for member
  end

  def active_loans(library, member_id) do
    # Currently borrowed books
  end

  def overdue_loans(library) do
    # All loans past due date
  end

  # Statistics
  def most_borrowed_books(library, limit \\ 10) do
    # Books with most loans
  end

  def active_members(library, days \\ 30) do
    # Members with activity in last N days
  end
end
```

#### 3. Protocol Implementations

```elixir
# Protocol for displaying items
defprotocol Library.Displayable do
  @doc "Returns a formatted string for display"
  def display(item)

  @doc "Returns a brief summary line"
  def summary(item)
end

defimpl Library.Displayable, for: Library.Book do
  def display(book) do
    """
    Title: #{book.title}
    Author: #{book.author}
    ISBN: #{book.isbn}
    Year: #{book.year}
    Genre: #{book.genre}
    Available: #{book.copies_available}/#{book.copies_total}
    """
  end

  def summary(book) do
    "#{book.title} by #{book.author} (#{book.copies_available} available)"
  end
end

defimpl Library.Displayable, for: Library.Member do
  # Implement display and summary
end

defimpl Library.Displayable, for: Library.Loan do
  # Implement display and summary
  # Show book title and member name if needed
end

# Make books enumerable by their properties
defimpl String.Chars, for: Library.Book do
  def to_string(book) do
    "#{book.title} by #{book.author}"
  end
end
```

#### 4. Import/Export Module

```elixir
defmodule Library.IO do
  # Import books from CSV
  def import_books(library, file_path) do
    # Stream-based import
    # CSV format: isbn,title,author,year,genre,copies
  end

  # Export books to CSV
  def export_books(library, file_path) do
    # Write all books to CSV
  end

  # Generate reports
  def generate_report(library, report_type, output_path) do
    # report_type: :inventory, :loans, :overdue, :statistics
    case report_type do
      :inventory -> inventory_report(library, output_path)
      :loans -> loans_report(library, output_path)
      :overdue -> overdue_report(library, output_path)
      :statistics -> statistics_report(library, output_path)
    end
  end

  defp inventory_report(library, path) do
    # Write detailed inventory
  end

  # ... other report functions
end
```

#### 5. Validation Module

```elixir
defmodule Library.Validation do
  # Validate book data
  def validate_book(book_data) do
    with {:ok, _} <- validate_isbn(book_data.isbn),
         {:ok, _} <- validate_year(book_data.year),
         {:ok, _} <- validate_copies(book_data.copies_total) do
      {:ok, book_data}
    else
      error -> error
    end
  end

  # Validate member data
  def validate_member(member_data) do
    # Email format, membership type, etc.
  end

  # Check loan eligibility
  def can_borrow?(library, member_id, isbn) do
    # Check: book available, member exists, member under loan limit
  end
end
```

### Technical Requirements

1. **Data Abstractions:**
   - All entities (Book, Member, Loan, Library) as structs
   - Clean interfaces through module functions
   - Data transparency (but clients use interface)

2. **Pattern Matching:**
   - Struct pattern matching in function heads
   - Case statements for complex branching
   - Guards for validation

3. **Immutable Updates:**
   - All operations return new library state
   - Hierarchical updates for nested changes
   - Optional: use put_in/update_in helpers

4. **Protocols:**
   - Displayable for formatting output
   - String.Chars for string conversion
   - Consider Enumerable for book collection

5. **Composition:**
   - Build complex operations from simple ones
   - Separate concerns (validation, queries, I/O)
   - Reusable helper functions

### Deliverables

1. **Source Files:**
   - `library.ex` - Core data structures
   - `library/operations.ex` - CRUD operations
   - `library/query.ex` - Query functions
   - `library/validation.ex` - Validation logic
   - `library/io.ex` - Import/export
   - `library/protocols.ex` - Protocol implementations

2. **Demo Script:**
   - `demo_library.exs` - Comprehensive demo
   - Create library with sample data
   - Demonstrate all operations
   - Show protocol usage
   - Generate reports

3. **Sample Data:**
   - `books.csv` - 20+ books
   - `members.csv` - 10+ members
   - Demonstrate import functionality

4. **Test Coverage:**
   - Test all CRUD operations
   - Test validation edge cases
   - Test protocol implementations

### Example Usage

```elixir
# Create library
library = Library.new()

# Add books
library = library
|> Library.Operations.add_book(
  Library.Book.new(
    "978-0134685991",
    "Effective Java",
    "Joshua Bloch",
    2018,
    :programming,
    3
  )
)

# Register member
{:ok, library, member_id} = Library.Operations.register_member(
  library,
  "Alice Johnson",
  "alice@example.com",
  :premium
)

# Borrow book
{:ok, library} = Library.Operations.borrow_book(library, member_id, "978-0134685991")

# Query
active = Library.Query.active_loans(library, member_id)
Enum.each(active, fn loan ->
  IO.puts(Library.Displayable.summary(loan))
end)

# Import books
library = Library.IO.import_books(library, "books.csv")

# Generate report
Library.IO.generate_report(library, :inventory, "inventory.txt")
```

### Bonus Challenges

1. **Fine System:**
   - Calculate fines for overdue books
   - Track member balance
   - Payment history

2. **Reservation System:**
   - Reserve books when all copies borrowed
   - Notification when book available
   - Queue management

3. **Enhanced Search:**
   - Full-text search across title/author/genre
   - Filters (year range, genre, availability)
   - Sorting options

4. **Statistics Dashboard:**
   - Most popular genres
   - Borrowing trends over time
   - Member activity statistics

5. **JSON Import/Export:**
   - Define JSON protocol
   - Implement for all types
   - Import/export to JSON

### Evaluation Criteria

**Data Abstraction (25 points)**
- Clean struct definitions (5 pts)
- Proper module interfaces (8 pts)
- Composition and separation of concerns (7 pts)
- Data hiding through interfaces (5 pts)

**Pattern Matching & Guards (20 points)**
- Struct pattern matching (8 pts)
- Effective use of guards (7 pts)
- Clean case statements (5 pts)

**Immutability (20 points)**
- Correct immutable updates (10 pts)
- Hierarchical updates (5 pts)
- Understanding of memory sharing (5 pts)

**Protocols (20 points)**
- Displayable implementation (8 pts)
- String.Chars implementation (7 pts)
- Understanding protocol dispatch (5 pts)

**Code Quality (15 points)**
- Clear, readable code (5 pts)
- Good function decomposition (5 pts)
- Error handling (5 pts)

### Tips for Success

1. Start with data structures - get them right first
2. Implement basic CRUD before complex features
3. Test each operation in iex as you build
4. Use pattern matching to validate inputs
5. Keep functions small and focused
6. Protocols last - add them when core functionality works
7. Use IO.inspect for debugging hierarchical updates
8. Build iteratively - add one feature at a time

---

## Success Checklist

Before moving to Chapter 5, ensure you can:

- [ ] Create module-based abstractions with clear interfaces
- [ ] Understand data transparency in Elixir
- [ ] Use maps to represent structured data
- [ ] Define and use structs for type safety
- [ ] Pattern match on struct types in function heads
- [ ] Understand that structs are specialized maps
- [ ] Perform immutable hierarchical updates
- [ ] Use put_in/update_in/get_in for nested updates
- [ ] Build data structures iteratively with Enum.reduce
- [ ] Understand and define protocols
- [ ] Implement protocols for custom types
- [ ] Use built-in protocols (String.Chars, Enumerable, Collectable)
- [ ] Understand protocol dispatch and polymorphism
- [ ] Compose abstractions to build complex systems
- [ ] Separate concerns across multiple modules

---

## Looking Ahead

Chapter 5 will cover:
- Concurrency primitives (processes)
- Message passing
- Stateful server processes
- Process registration

The data abstractions and immutable structures from Chapter 4 become crucial in concurrent environments, where multiple processes operate on shared data patterns!
