# ContactManager Quick Reference

## Running the Project

```bash
# Compile all modules
elixirc contact_manager.ex formatter.ex query.ex examples.ex bonus.ex

# Run demo
elixir demo.exs

# Run comprehensive tests
elixir test_all.exs

# Interactive mode
iex
c "contact_manager.ex"
c "examples.ex"
ContactManager.Examples.demo()
```

## Quick API Reference

### Creating and Managing Database

```elixir
# Create empty database
db = ContactManager.new()

# Create contact
{:ok, contact} = ContactManager.create_contact(
  "John Doe", 
  "john@example.com", 
  "555-0100",
  tags: [:work, :vip],
  notes: "Important client"
)

# Add to database
db = ContactManager.add(db, contact)

# Get contact
{:ok, contact} = ContactManager.get_contact(db, 1)

# List all
contacts = ContactManager.list_contacts(db)

# Update
{:ok, {db, updated}} = ContactManager.update_contact(db, 1, %{notes: "New notes"})

# Delete
{:ok, {db, deleted}} = ContactManager.delete_contact(db, 1)
```

### Searching

```elixir
# By tag
vips = ContactManager.search_by_tag(db, :vip)

# By name (partial, case-insensitive)
johns = ContactManager.search_by_name(db, "john")
```

### Formatting

```elixir
alias ContactManager.Formatter

# Single contact
Formatter.format_contact(contact) |> IO.puts()

# Summary
Formatter.format_summary(contact)
# Output: "[1] John Doe <john@example.com> (555-0100) [work, vip]"

# List
Formatter.format_list(contacts) |> IO.puts()

# CSV export
csv = Formatter.export_csv(contacts)
File.write!("contacts.csv", csv)
```

### Advanced Queries

```elixir
alias ContactManager.Query

# Filter by field
work_contacts = Query.filter_by(contacts, :email, "work.com")

# Sort
sorted = Query.sort_by(contacts, :name)          # ascending
sorted = Query.sort_by(contacts, :created_at, :desc)  # descending

# Group by tag
by_tag = Query.group_by_tag(contacts)
# Returns: %{work: [...], personal: [...]}

# Group by any field
by_domain = Query.group_by(contacts, :email)

# Multi-criteria search
results = Query.search(contacts, %{name: "Alice", tags: [:work]})

# Contains (for list fields)
vips = Query.contains(contacts, :tags, :vip)

# Pagination
{page_items, total_pages} = Query.paginate(contacts, 1, 10)

# Top N
top_5 = Query.top_n(contacts, :created_at, 5)
```

### Bonus Features

```elixir
alias ContactManager.Bonus

# Bulk create
data = [
  {"Alice", "alice@test.com", "555-0100", tags: [:work]},
  {"Bob", "bob@test.com", "555-0101", tags: [:personal]}
]
{:ok, {contacts, errors}} = Bonus.bulk_create(data)

# Bulk update
{:ok, {db, updated, failed}} = Bonus.bulk_update(db, [1, 2, 3], %{notes: "Updated"})

# Bulk tag
{:ok, {db, count}} = Bonus.bulk_tag(db, [1, 2], :urgent)

# Statistics
stats = Bonus.stats(db)
Bonus.stats_report(db) |> IO.puts()

# CSV import
{:ok, contacts} = Bonus.import_csv(csv_data)

# JSON export
json = Bonus.export_json(contacts, pretty: true)
```

## Common Patterns

### Pipeline Operations

```elixir
# Find and display work contacts sorted by name
db
|> ContactManager.list_contacts()
|> Query.contains(:tags, :work)
|> Query.sort_by(:name)
|> Formatter.format_summary_list()
|> IO.puts()
```

### Error Handling

```elixir
# Pattern match on results
case ContactManager.create_contact(name, email, phone) do
  {:ok, contact} ->
    IO.puts("Created: #{contact.name}")
    
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end

# Using with statement (more advanced)
with {:ok, contact} <- ContactManager.create_contact(name, email, phone),
     db <- ContactManager.add(db, contact),
     {:ok, {new_db, updated}} <- ContactManager.update_contact(db, contact.id, fields) do
  {:ok, new_db}
else
  {:error, reason} -> {:error, reason}
end
```

### Sample Data

```elixir
# Get sample contacts
samples = ContactManager.Examples.sample_contacts()

# Get pre-populated database
db = ContactManager.Examples.sample_database()

# Run quick demo
ContactManager.Examples.quick_demo()

# Run full demo
ContactManager.Examples.demo()
```

## Key Concepts Demonstrated

1. **Immutability**: All operations return new data structures
2. **Pattern Matching**: Function clauses and result tuples
3. **Tagged Tuples**: `{:ok, result}` and `{:error, reason}`
4. **Maps**: For flexible record structures
5. **Lists**: For collections
6. **Atoms**: For tags and status codes
7. **Higher-Order Functions**: Enum.map, Enum.filter, etc.
8. **Pipe Operator**: Chaining transformations
9. **Type Specs**: @spec annotations
10. **Documentation**: @doc and @moduledoc

## Performance Notes

- Get by ID: O(1)
- Update by ID: O(1)
- Delete by ID: O(1)
- List all: O(n)
- Search: O(n)
- Sort: O(n log n)
- Group by tag: O(n × m) where m = avg tags per contact

## File Structure

```
contact-manager/
├── contact_manager.ex    # Core CRUD operations
├── formatter.ex          # Display and export formatting
├── query.ex             # Advanced querying
├── examples.ex          # Sample data and demos
├── bonus.ex             # Bonus features (import/export, stats)
├── demo.exs             # Runnable demo script
├── test_all.exs         # Comprehensive test suite
├── README.md            # Full documentation
├── ANALYSIS.md          # Design analysis
└── QUICK_REFERENCE.md   # This file
```

## Tips

1. **Always use the database**: Operations return new databases, use them!
   ```elixir
   # ✗ Wrong
   {:ok, {new_db, _}} = ContactManager.update_contact(db, 1, %{name: "New"})
   ContactManager.get_contact(db, 1)  # Still has old data!
   
   # ✓ Correct
   {:ok, {new_db, _}} = ContactManager.update_contact(db, 1, %{name: "New"})
   ContactManager.get_contact(new_db, 1)  # Has updated data
   ```

2. **Use pipelines for complex operations**
   ```elixir
   # ✓ Clean and readable
   db
   |> ContactManager.list_contacts()
   |> Query.contains(:tags, :work)
   |> Query.sort_by(:name)
   |> Enum.take(5)
   ```

3. **Pattern match on results**
   ```elixir
   # ✓ Handle both success and failure
   case operation() do
     {:ok, result} -> # handle success
     {:error, reason} -> # handle error
   end
   ```

4. **Use sample data for testing**
   ```elixir
   db = ContactManager.Examples.sample_database()
   # Now you have 10 contacts to work with
   ```
