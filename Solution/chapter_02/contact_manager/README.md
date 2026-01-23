# Contact Manager

----
I don't know some shit. Claude has done this entire bit and has introduced many concepts I have not yet learnt. I will skip this and come back to this section when I am mature enough for it.
----

A comprehensive contact management system built with Elixir, demonstrating functional programming principles, immutable data structures, and effective use of Elixir's type system.

## Overview

This project showcases the following Elixir concepts from "Elixir in Action" Chapter 2:
- Module organization and hierarchical naming
- Pattern matching and function clauses
- Immutable data structures (maps, lists, tuples)
- Atoms for tags and status codes
- Error handling with `{:ok, result}` and `{:error, reason}` tuples
- Higher-order functions and the Enum module
- Type specifications with `@spec`
- Documentation with `@doc` and `@moduledoc`

## Project Structure

```
contact_manager/
├── contact_manager.ex    # Core CRUD operations
├── formatter.ex          # Output formatting (text, CSV)
├── query.ex             # Advanced querying and filtering
├── examples.ex          # Sample data and demonstrations
├── demo.exs             # Executable demo script
├── README.md            # This file
└── ANALYSIS.md          # Design analysis and trade-offs
```

## Installation & Setup

### Prerequisites
- Elixir 1.14 or later
- Erlang/OTP 25 or later

### Quick Start

1. **Clone or download the files** to a directory

2. **Compile the modules:**
   ```bash
   elixirc contact_manager.ex formatter.ex query.ex examples.ex
   ```

3. **Run the demo:**
   ```bash
   elixir demo.exs
   ```

4. **Or use in iex (interactive Elixir):**
   ```bash
   iex
   ```
   
   Then in iex:
   ```elixir
   c "contact_manager.ex"
   c "formatter.ex"
   c "query.ex"
   c "examples.ex"
   
   # Run the demo
   ContactManager.Examples.demo()
   ```

## API Overview

### ContactManager (Core Module)

The main module for contact management operations.

#### Data Structure

Each contact is represented as a map:

```elixir
%{
  id: 1,                              # Unique integer ID
  name: "John Doe",                   # String
  email: "john@example.com",          # String (validated)
  phone: "555-0100",                  # String
  tags: [:work, :vip],                # List of atoms
  created_at: ~U[2024-01-01 12:00:00Z], # DateTime
  notes: "Some notes"                 # String
}
```

#### Core Functions

**Creating Contacts**
```elixir
# Basic contact
{:ok, contact} = ContactManager.create_contact(
  "John Doe",
  "john@example.com",
  "555-0100"
)

# With optional parameters
{:ok, contact} = ContactManager.create_contact(
  "Jane Smith",
  "jane@example.com",
  "555-0101",
  tags: [:work, :vip],
  notes: "Important client"
)
```

**Database Management**
```elixir
# Create empty database
db = ContactManager.new()

# Add contact to database
db = ContactManager.add(db, contact)

# List all contacts
contacts = ContactManager.list_contacts(db)

# Get specific contact
{:ok, contact} = ContactManager.get_contact(db, 1)
```

**Updating Contacts**
```elixir
{:ok, {new_db, updated}} = ContactManager.update_contact(
  db,
  1,
  %{notes: "Updated notes", tags: [:work, :vip, :urgent]}
)
```

**Deleting Contacts**
```elixir
{:ok, {new_db, deleted}} = ContactManager.delete_contact(db, 1)
```

**Searching**
```elixir
# Search by tag
vip_contacts = ContactManager.search_by_tag(db, :vip)

# Search by name (partial, case-insensitive)
john_contacts = ContactManager.search_by_name(db, "john")
```

### ContactManager.Formatter

Functions for formatting and exporting contact data.

```elixir
# Format single contact for display
formatted = ContactManager.Formatter.format_contact(contact)
IO.puts(formatted)

# Format list of contacts
formatted_list = ContactManager.Formatter.format_list(contacts)

# One-line summaries
summary = ContactManager.Formatter.format_summary(contact)
# Output: "[1] John Doe <john@example.com> (555-0100) [work, vip]"

# Export to CSV
csv = ContactManager.Formatter.export_csv(contacts)
File.write!("contacts.csv", csv)
```

### ContactManager.Query

Advanced querying and data manipulation.

```elixir
alias ContactManager.Query

# Filter by any field
work_email_contacts = Query.filter_by(contacts, :email, "work.com")

# Sort by field
sorted = Query.sort_by(contacts, :name)           # ascending
sorted = Query.sort_by(contacts, :name, :desc)    # descending

# Group by tag
grouped = Query.group_by_tag(contacts)
# Returns: %{work: [...], personal: [...], vip: [...]}

# Group by any field
by_email_domain = Query.group_by(contacts, :email)

# Multi-criteria search
results = Query.search(contacts, %{name: "Alice", tags: [:work]})

# Check if list field contains value
vip_contacts = Query.contains(contacts, :tags, :vip)

# Pagination
{page_items, total_pages} = Query.paginate(contacts, 1, 10)

# Top N by field
top_5 = Query.top_n(contacts, :created_at, 5)
```

### ContactManager.Examples

Sample data and demonstrations.

```elixir
# Get sample contacts
samples = ContactManager.Examples.sample_contacts()

# Get sample database
db = ContactManager.Examples.sample_database()

# Run full demonstration
ContactManager.Examples.demo()

# Run quick demo
ContactManager.Examples.quick_demo()
```

## Example Usage

### Complete Workflow Example

```elixir
# 1. Create database
db = ContactManager.new()

# 2. Create contacts
{:ok, alice} = ContactManager.create_contact(
  "Alice Johnson",
  "alice@techcorp.com",
  "555-0101",
  tags: [:work, :vip],
  notes: "CEO of TechCorp"
)

{:ok, bob} = ContactManager.create_contact(
  "Bob Smith",
  "bob@personal.com",
  "555-0102",
  tags: [:personal]
)

# 3. Add to database
db = db 
  |> ContactManager.add(alice)
  |> ContactManager.add(bob)

# 4. Search and filter
vips = ContactManager.search_by_tag(db, :vip)
IO.puts("VIP Contacts: #{length(vips)}")

# 5. Update contact
{:ok, {db, updated}} = ContactManager.update_contact(
  db,
  alice.id,
  %{tags: [:work, :vip, :urgent]}
)

# 6. Advanced queries
work_contacts = 
  db
  |> ContactManager.list_contacts()
  |> ContactManager.Query.contains(:tags, :work)
  |> ContactManager.Query.sort_by(:name)

# 7. Export
csv = ContactManager.Formatter.export_csv(work_contacts)
File.write!("work_contacts.csv", csv)

# 8. Display
ContactManager.Formatter.format_list(work_contacts)
|> IO.puts()
```

### Pipeline Example

```elixir
# Functional pipeline for complex operations
db
|> ContactManager.list_contacts()
|> ContactManager.Query.contains(:tags, :work)
|> ContactManager.Query.sort_by(:created_at, :desc)
|> Enum.take(5)
|> ContactManager.Formatter.format_summary_list()
|> IO.puts()
```

## Error Handling

All functions that can fail return tagged tuples:

```elixir
# Success
{:ok, contact} = ContactManager.create_contact(...)
{:ok, {new_db, updated}} = ContactManager.update_contact(...)

# Errors
{:error, "Name cannot be empty"} = ContactManager.create_contact("", "email@test.com", "555-0100")
{:error, "Invalid email format"} = ContactManager.create_contact("John", "not-email", "555-0100")
{:error, :not_found} = ContactManager.get_contact(db, 999)
```

## Validation Rules

- **Name**: Cannot be empty, automatically normalized (capitalized)
- **Email**: Must match basic email format (contains @ and domain)
- **Phone**: Cannot be empty
- **Tags**: Must be a list of atoms
- **ID**: Auto-generated, unique

## Performance Characteristics

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| `create_contact` | O(1) | Just creates a map |
| `add` (to database) | O(1) | Map insertion |
| `get_contact` | O(1) | Map lookup by key |
| `update_contact` | O(1) | Map update |
| `delete_contact` | O(1) | Map deletion |
| `list_contacts` | O(n) | Converts map to list |
| `search_by_tag` | O(n) | Linear scan |
| `search_by_name` | O(n) | Linear scan |
| `sort_by` | O(n log n) | Standard sorting |
| `group_by_tag` | O(n*m) | n contacts, m tags per contact |

Where:
- n = number of contacts
- m = average tags per contact

## Design Decisions

### Why Maps for Storage?

We use a map with ID as the key for O(1) lookups, updates, and deletes:
```elixir
%{
  1 => %{id: 1, name: "Alice", ...},
  2 => %{id: 2, name: "Bob", ...}
}
```

### Why Tuples for Results?

Following Elixir conventions, we use `{:ok, result}` and `{:error, reason}` to:
- Make success/failure explicit
- Enable pattern matching
- Avoid exceptions for expected failures
- Compose well with `with` statements (covered in later chapters)

### Immutability Benefits

Every operation returns a new data structure:
```elixir
# Old database unchanged
{:ok, {new_db, updated}} = ContactManager.update_contact(old_db, 1, %{name: "New Name"})

# Can still access old_db if needed (for undo, etc.)
```

This enables:
- Time-travel debugging
- Undo/redo functionality
- Safe concurrent access (in later chapters)
- Easier testing and reasoning

## Testing

To test the system:

```bash
# Run the demo
elixir demo.exs

# Or in iex
iex> c "examples.ex"
iex> ContactManager.Examples.demo()
```

## Next Steps

To extend this system (covered in later chapters):

1. **Add persistence** (Chapter 3-4): Save to files or database
2. **Add concurrency** (Chapter 5-7): Use GenServer for state management
3. **Add supervision** (Chapter 8): Fault-tolerant operation
4. **Add web interface** (Chapter 13): Phoenix web application
5. **Add authentication**: Secure multi-user access

## License

Educational project for learning Elixir.

## References

- "Elixir in Action" by Saša Jurić - Chapter 2
- Elixir documentation: https://hexdocs.pm/elixir/
