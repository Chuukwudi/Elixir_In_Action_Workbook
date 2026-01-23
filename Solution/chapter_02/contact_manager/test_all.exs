#!/usr/bin/env elixir

# Comprehensive test script for ContactManager
# Run with: elixir test_all.exs

# Compile all modules
IO.puts("Compiling modules...")
Code.compile_file("contact_manager.ex")
Code.compile_file("formatter.ex")
Code.compile_file("query.ex")
Code.compile_file("examples.ex")
Code.compile_file("bonus.ex")
IO.puts("✓ All modules compiled\n")

# Test helper functions
defmodule TestHelper do
  def assert(true, _message), do: :ok

  def assert(false, message) do
    IO.puts("✗ FAILED: #{message}")
    System.halt(1)
  end

  def test(description, fun) do
    IO.write("  Testing #{description}... ")

    try do
      fun.()
      IO.puts("✓")
      :ok
    rescue
      e ->
        IO.puts("✗")
        IO.puts("    Error: #{Exception.message(e)}")
        reraise e, __STACKTRACE__
    end
  end
end

import TestHelper

IO.puts("=" <> String.duplicate("=", 69))
IO.puts("RUNNING COMPREHENSIVE TESTS")
IO.puts(String.duplicate("=", 70) <> "\n")

# ==============================================================================
# TEST SUITE 1: Contact Creation
# ==============================================================================

IO.puts("Suite 1: Contact Creation")

test "create valid contact", fn ->
  {:ok, contact} = ContactManager.create_contact("Alice Smith", "alice@test.com", "555-0100")
  assert(contact.name == "Alice Smith", "Name should match")
  assert(contact.email == "alice@test.com", "Email should match")
  assert(is_integer(contact.id), "ID should be an integer")
end

test "create contact with tags", fn ->
  {:ok, contact} =
    ContactManager.create_contact("Bob", "bob@test.com", "555-0101", tags: [:work, :vip])

  assert(:work in contact.tags, "Should have work tag")
  assert(:vip in contact.tags, "Should have vip tag")
end

test "name normalization", fn ->
  {:ok, contact} = ContactManager.create_contact("alice smith", "alice@test.com", "555-0100")
  assert(contact.name == "Alice Smith", "Name should be capitalized")
end

test "validation: empty name", fn ->
  {:error, reason} = ContactManager.create_contact("", "alice@test.com", "555-0100")
  assert(reason =~ "Name", "Should reject empty name")
end

test "validation: invalid email", fn ->
  {:error, reason} = ContactManager.create_contact("Alice", "not-an-email", "555-0100")
  assert(reason =~ "email", "Should reject invalid email")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 2: Database Operations
# ==============================================================================

IO.puts("Suite 2: Database Operations")

test "create and add contact to database", fn ->
  db = ContactManager.new()
  {:ok, contact} = ContactManager.create_contact("Test", "test@test.com", "555-0100")
  new_db = ContactManager.add(db, contact)
  assert(map_size(new_db) == 1, "Database should have 1 contact")
end

test "get contact by id", fn ->
  {:ok, contact} = ContactManager.create_contact("Test", "test@test.com", "555-0100")
  db = ContactManager.new() |> ContactManager.add(contact)
  {:ok, retrieved} = ContactManager.get_contact(db, contact.id)
  assert(retrieved.name == "Test", "Should retrieve correct contact")
end

test "get non-existent contact", fn ->
  db = ContactManager.new()
  {:error, :not_found} = ContactManager.get_contact(db, 999)
  assert(true, "Should return not_found")
end

test "list all contacts", fn ->
  db =
    ContactManager.new()
    |> then(fn db ->
      {:ok, c1} = ContactManager.create_contact("A", "a@test.com", "1")
      {:ok, c2} = ContactManager.create_contact("B", "b@test.com", "2")
      db |> ContactManager.add(c1) |> ContactManager.add(c2)
    end)

  contacts = ContactManager.list_contacts(db)
  assert(length(contacts) == 2, "Should have 2 contacts")
end

test "update contact", fn ->
  {:ok, contact} = ContactManager.create_contact("Old Name", "old@test.com", "555-0100")
  db = ContactManager.new() |> ContactManager.add(contact)
  {:ok, {new_db, updated}} = ContactManager.update_contact(db, contact.id, %{name: "New Name"})
  assert(updated.name == "New Name", "Name should be updated")
  assert(updated.email == "old@test.com", "Email should be preserved")
end

test "delete contact", fn ->
  {:ok, contact} = ContactManager.create_contact("Delete Me", "del@test.com", "555-0100")
  db = ContactManager.new() |> ContactManager.add(contact)
  {:ok, {new_db, deleted}} = ContactManager.delete_contact(db, contact.id)
  assert(map_size(new_db) == 0, "Database should be empty")
  assert(deleted.name == "Delete Me", "Should return deleted contact")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 3: Search Operations
# ==============================================================================

IO.puts("Suite 3: Search Operations")

test "search by tag", fn ->
  db = ContactManager.Examples.sample_database()
  vip_contacts = ContactManager.search_by_tag(db, :vip)
  assert(length(vip_contacts) > 0, "Should find VIP contacts")
  assert(Enum.all?(vip_contacts, fn c -> :vip in c.tags end), "All should have VIP tag")
end

test "search by name (case insensitive)", fn ->
  db = ContactManager.Examples.sample_database()
  results = ContactManager.search_by_name(db, "alice")
  assert(length(results) > 0, "Should find Alice")
  assert(Enum.all?(results, fn c -> String.downcase(c.name) =~ "alice" end), "All should match")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 4: Formatting
# ==============================================================================

IO.puts("Suite 4: Formatting")

test "format single contact", fn ->
  {:ok, contact} = ContactManager.create_contact("Test", "test@test.com", "555-0100")
  formatted = ContactManager.Formatter.format_contact(contact)
  assert(is_binary(formatted), "Should return string")
  assert(formatted =~ "Test", "Should contain name")
end

test "format summary", fn ->
  {:ok, contact} =
    ContactManager.create_contact("Test", "test@test.com", "555-0100", tags: [:work])

  summary = ContactManager.Formatter.format_summary(contact)
  assert(summary =~ "Test", "Should contain name")
  assert(summary =~ "work", "Should contain tag")
end

test "export CSV", fn ->
  contacts = Enum.take(ContactManager.Examples.sample_contacts(), 2)
  csv = ContactManager.Formatter.export_csv(contacts)
  assert(csv =~ "ID,Name,Email", "Should have header")
  lines = String.split(csv, "\n", trim: true)
  assert(length(lines) == 3, "Should have header + 2 rows")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 5: Query Operations
# ==============================================================================

IO.puts("Suite 5: Query Operations")

test "filter by field", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  filtered = ContactManager.Query.filter_by(contacts, :name, "Alice Johnson")
  assert(length(filtered) == 1, "Should find exactly one Alice Johnson")
end

test "sort by name ascending", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  sorted = ContactManager.Query.sort_by(contacts, :name)
  names = Enum.map(sorted, & &1.name)
  assert(names == Enum.sort(names), "Should be sorted alphabetically")
end

test "sort by name descending", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  sorted = ContactManager.Query.sort_by(contacts, :name, :desc)
  names = Enum.map(sorted, & &1.name)
  assert(names == Enum.sort(names, :desc), "Should be sorted reverse alphabetically")
end

test "group by tag", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  grouped = ContactManager.Query.group_by_tag(contacts)
  assert(is_map(grouped), "Should return a map")
  assert(Map.has_key?(grouped, :work), "Should have work tag")
  assert(is_list(grouped[:work]), "Each group should be a list")
end

test "multi-criteria search", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  results = ContactManager.Query.search(contacts, %{name: "Alice Johnson"})
  assert(length(results) == 1, "Should find one result")
end

test "contains (list field)", fn ->
  contacts = ContactManager.Examples.sample_contacts()
  vip_contacts = ContactManager.Query.contains(contacts, :tags, :vip)
  assert(Enum.all?(vip_contacts, fn c -> :vip in c.tags end), "All should have VIP tag")
end

test "pagination", fn ->
  contacts = Enum.map(1..25, fn i -> %{id: i, name: "Contact #{i}"} end)
  {page1, total_pages} = ContactManager.Query.paginate(contacts, 1, 10)
  assert(length(page1) == 10, "First page should have 10 items")
  assert(total_pages == 3, "Should have 3 pages total")

  {page2, _} = ContactManager.Query.paginate(contacts, 2, 10)
  assert(length(page2) == 10, "Second page should have 10 items")

  {page3, _} = ContactManager.Query.paginate(contacts, 3, 10)
  assert(length(page3) == 5, "Last page should have 5 items")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 6: Bonus Features
# ==============================================================================

IO.puts("Suite 6: Bonus Features")

test "bulk create", fn ->
  data = [
    {"Alice", "alice@test.com", "555-0100", []},
    {"Bob", "bob@test.com", "555-0101", []},
    {"", "invalid@test.com", "555-0102", []}
  ]

  {:ok, {contacts, errors}} = ContactManager.Bonus.bulk_create(data)
  assert(length(contacts) == 2, "Should create 2 valid contacts")
  assert(length(errors) == 1, "Should have 1 error")
end

test "bulk update", fn ->
  db = ContactManager.Examples.sample_database()
  ids = [1, 2, 3]
  {:ok, {new_db, updated, failed}} = ContactManager.Bonus.bulk_update(db, ids, %{notes: "Bulk updated"})
  assert(length(updated) == 3, "Should update 3 contacts")
  assert(Enum.all?(updated, fn c -> c.notes == "Bulk updated" end), "All should be updated")
end

test "bulk tag", fn ->
  db = ContactManager.Examples.sample_database()
  ids = [1, 2]
  {:ok, {new_db, count}} = ContactManager.Bonus.bulk_tag(db, ids, :urgent)
  assert(count == 2, "Should tag 2 contacts")

  {:ok, contact1} = ContactManager.get_contact(new_db, 1)
  assert(:urgent in contact1.tags, "Should have urgent tag")
end

test "statistics", fn ->
  db = ContactManager.Examples.sample_database()
  stats = ContactManager.Bonus.stats(db)
  assert(stats.total_contacts == 10, "Should have 10 contacts")
  assert(is_map(stats.tags_distribution), "Should have tag distribution")
  assert(is_number(stats.average_tags_per_contact), "Should calculate average")
end

test "CSV import/export round trip", fn ->
  original = Enum.take(ContactManager.Examples.sample_contacts(), 3)
  csv = ContactManager.Formatter.export_csv(original)
  {:ok, imported} = ContactManager.Bonus.import_csv(csv)
  assert(length(imported) == 3, "Should import 3 contacts")
  assert(Enum.at(imported, 0).name == Enum.at(original, 0).name, "Names should match")
end

IO.puts("")

# ==============================================================================
# TEST SUITE 7: Immutability
# ==============================================================================

IO.puts("Suite 7: Immutability")

test "original database unchanged after update", fn ->
  {:ok, contact} = ContactManager.create_contact("Original", "orig@test.com", "555-0100")
  original_db = ContactManager.new() |> ContactManager.add(contact)

  {:ok, {new_db, _}} = ContactManager.update_contact(original_db, contact.id, %{name: "Updated"})

  {:ok, from_original} = ContactManager.get_contact(original_db, contact.id)
  {:ok, from_new} = ContactManager.get_contact(new_db, contact.id)

  assert(from_original.name == "Original", "Original DB should be unchanged")
  assert(from_new.name == "Updated", "New DB should have update")
end

test "original list unchanged after filter", fn ->
  original_contacts = ContactManager.Examples.sample_contacts()
  original_count = length(original_contacts)

  _filtered = ContactManager.Query.filter_by(original_contacts, :name, "Alice Johnson")

  assert(length(original_contacts) == original_count, "Original list should be unchanged")
end

IO.puts("")

# ==============================================================================
# ALL TESTS PASSED
# ==============================================================================

IO.puts(String.duplicate("=", 70))
IO.puts("✓ ALL TESTS PASSED!")
IO.puts(String.duplicate("=", 70))
IO.puts("")

# Run the demo
IO.puts("Running demonstration...\n")
ContactManager.Examples.demo()

IO.puts("\n" <> String.duplicate("=", 70))
IO.puts("✓ TEST SUITE COMPLETE")
IO.puts(String.duplicate("=", 70))
