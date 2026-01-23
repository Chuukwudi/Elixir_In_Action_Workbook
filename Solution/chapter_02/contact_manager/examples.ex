defmodule ContactManager.Examples do
  @moduledoc """
  Provides sample data and demonstrations for the ContactManager system.

  This module includes example contacts and a demo function that
  showcases all the functionality of the contact management system.
  """

  alias ContactManager.{Formatter, Query}

  @doc """
  Generates a list of sample contacts for testing and demonstration.

  ## Returns
    - List of 10 sample contacts with varied data
  """
  @spec sample_contacts() :: list(map())
  def sample_contacts do
    [
      %{
        id: 1,
        name: "Alice Johnson",
        email: "alice.johnson@techcorp.com",
        phone: "555-0101",
        tags: [:work, :vip, :tech],
        created_at: ~U[2024-01-15 09:30:00Z],
        notes: "CEO of TechCorp, primary business contact"
      },
      %{
        id: 2,
        name: "Bob Smith",
        email: "bob.smith@email.com",
        phone: "555-0102",
        tags: [:personal, :sports],
        created_at: ~U[2024-02-20 14:15:00Z],
        notes: "Tennis partner, meets every Saturday"
      },
      %{
        id: 3,
        name: "Carol White",
        email: "carol.white@consulting.com",
        phone: "555-0103",
        tags: [:work, :consulting],
        created_at: ~U[2024-01-10 11:00:00Z],
        notes: "Business consultant for Q1 project"
      },
      %{
        id: 4,
        name: "David Lee",
        email: "david.lee@startup.io",
        phone: "555-0104",
        tags: [:work, :tech, :vip],
        created_at: ~U[2024-03-05 16:45:00Z],
        notes: "CTO of promising startup, potential partnership"
      },
      %{
        id: 5,
        name: "Emma Davis",
        email: "emma.davis@gmail.com",
        phone: "555-0105",
        tags: [:personal, :family],
        created_at: ~U[2024-02-14 10:20:00Z],
        notes: "Cousin, lives in Seattle"
      },
      %{
        id: 6,
        name: "Frank Miller",
        email: "frank.miller@law.com",
        phone: "555-0106",
        tags: [:work, :legal],
        created_at: ~U[2024-01-25 13:30:00Z],
        notes: "Corporate lawyer, handles contracts"
      },
      %{
        id: 7,
        name: "Grace Chen",
        email: "grace.chen@design.studio",
        phone: "555-0107",
        tags: [:work, :creative],
        created_at: ~U[2024-03-12 09:00:00Z],
        notes: "Lead designer for website redesign project"
      },
      %{
        id: 8,
        name: "Henry Wilson",
        email: "hwilson@personal.net",
        phone: "555-0108",
        tags: [:personal, :sports, :music],
        created_at: ~U[2024-02-28 15:45:00Z],
        notes: "College friend, bass player"
      },
      %{
        id: 9,
        name: "Iris Rodriguez",
        email: "iris.r@marketing.agency",
        phone: "555-0109",
        tags: [:work, :marketing, :vip],
        created_at: ~U[2024-01-08 08:15:00Z],
        notes: "Marketing director, manages our campaigns"
      },
      %{
        id: 10,
        name: "Jack Thompson",
        email: "jack.t@email.com",
        phone: "555-0110",
        tags: [:personal],
        created_at: ~U[2024-03-20 12:00:00Z],
        notes: "Neighbor, borrowed lawn mower"
      }
    ]
  end

  @doc """
  Creates a contact database with sample contacts.

  ## Returns
    - Map of sample contacts keyed by ID
  """
  @spec sample_database() :: map()
  def sample_database do
    sample_contacts()
    |> Enum.map(fn contact -> {contact.id, contact} end)
    |> Enum.into(%{})
  end

  @doc """
  Runs a comprehensive demonstration of all ContactManager functionality.

  This function creates contacts, performs various operations, and
  displays the results in a formatted way.
  """
  @spec demo() :: :ok
  def demo do
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("CONTACT MANAGER DEMONSTRATION")
    IO.puts(String.duplicate("=", 70) <> "\n")

    # Initialize database
    db = ContactManager.new()

    # Demo 1: Creating contacts
    demo_create_contacts(db)
  end

  defp demo_create_contacts(db) do
    IO.puts(">>> DEMO 1: Creating Contacts\n")

    # Create a new contact
    IO.puts("Creating contact: John Doe")

    case ContactManager.create_contact("john doe", "john.doe@example.com", "555-1234",
           tags: [:work, :tech],
           notes: "Software engineer"
         ) do
      {:ok, contact} ->
        IO.puts("✓ Contact created successfully!")
        IO.puts(Formatter.format_contact(contact))

        db = ContactManager.add(db, contact)
        demo_validation(db)

      {:error, reason} ->
        IO.puts("✗ Failed: #{reason}")
    end
  end

  defp demo_validation(db) do
    IO.puts("\n>>> DEMO 2: Validation\n")

    IO.puts("Attempting to create contact with invalid email...")

    case ContactManager.create_contact("Invalid User", "not-an-email", "555-9999") do
      {:ok, _contact} ->
        IO.puts("✗ Should have failed!")

      {:error, reason} ->
        IO.puts("✓ Validation worked: #{reason}")
    end

    demo_with_sample_data(db)
  end

  defp demo_with_sample_data(db) do
    IO.puts("\n>>> DEMO 3: Working with Sample Data\n")

    # Load sample contacts
    IO.puts("Loading sample contacts...")
    db = sample_database()
    contacts = ContactManager.list_contacts(db)

    IO.puts("✓ Loaded #{length(contacts)} contacts\n")
    IO.puts(Formatter.format_summary_list(Enum.take(contacts, 3)))
    IO.puts("... (#{length(contacts) - 3} more contacts)\n")

    demo_search(db)
  end

  defp demo_search(db) do
    IO.puts("\n>>> DEMO 4: Searching Contacts\n")

    # Search by tag
    IO.puts("Searching for VIP contacts...")
    vip_contacts = ContactManager.search_by_tag(db, :vip)
    IO.puts("✓ Found #{length(vip_contacts)} VIP contacts:")
    IO.puts(Formatter.format_summary_list(vip_contacts))

    # Search by name
    IO.puts("\nSearching for contacts named 'Lee'...")
    lee_contacts = ContactManager.search_by_name(db, "Lee")
    IO.puts("✓ Found #{length(lee_contacts)} contacts:")
    IO.puts(Formatter.format_summary_list(lee_contacts))

    demo_update(db)
  end

  defp demo_update(db) do
    IO.puts("\n>>> DEMO 5: Updating Contacts\n")

    IO.puts("Updating contact ID 1...")

    case ContactManager.update_contact(db, 1, %{notes: "CEO - Updated contact info"}) do
      {:ok, {new_db, updated}} ->
        IO.puts("✓ Contact updated successfully!")
        IO.puts(Formatter.format_contact(updated))
        demo_query(new_db)

      {:error, reason} ->
        IO.puts("✗ Update failed: #{reason}")
    end
  end

  defp demo_query(db) do
    IO.puts("\n>>> DEMO 6: Advanced Queries\n")

    contacts = ContactManager.list_contacts(db)

    # Group by tag
    IO.puts("Grouping contacts by tag...")
    grouped = Query.group_by_tag(contacts)

    Enum.each(grouped, fn {tag, tag_contacts} ->
      IO.puts("  #{tag}: #{length(tag_contacts)} contacts")
    end)

    # Sort by name
    IO.puts("\nSorting contacts by name (first 3):")
    sorted = Query.sort_by(contacts, :name)
    IO.puts(Formatter.format_summary_list(Enum.take(sorted, 3)))

    # Filter by field
    IO.puts("\nFiltering work contacts...")
    work_contacts = Query.contains(contacts, :tags, :work)
    IO.puts("✓ Found #{length(work_contacts)} work contacts")

    demo_csv_export(db)
  end

  defp demo_csv_export(db) do
    IO.puts("\n>>> DEMO 7: CSV Export\n")

    contacts = ContactManager.list_contacts(db)
    csv = Formatter.export_csv(Enum.take(contacts, 3))

    IO.puts("Exporting first 3 contacts to CSV:")
    IO.puts(csv)

    demo_delete(db)
  end

  defp demo_delete(db) do
    IO.puts("\n>>> DEMO 8: Deleting Contacts\n")

    IO.puts("Deleting contact ID 10...")

    case ContactManager.delete_contact(db, 10) do
      {:ok, {new_db, deleted}} ->
        IO.puts("✓ Contact deleted successfully!")
        IO.puts("Deleted: #{deleted.name}")
        remaining = ContactManager.list_contacts(new_db)
        IO.puts("Remaining contacts: #{length(remaining)}")
        demo_statistics(new_db)

      {:error, reason} ->
        IO.puts("✗ Delete failed: #{reason}")
    end
  end

  defp demo_statistics(db) do
    IO.puts("\n>>> DEMO 9: Statistics\n")

    contacts = ContactManager.list_contacts(db)

    # Calculate statistics
    total = length(contacts)
    tags_count = Query.group_by_tag(contacts) |> map_size()

    all_tags =
      contacts
      |> Enum.flat_map(& &1.tags)
      |> Enum.frequencies()

    IO.puts("Total contacts: #{total}")
    IO.puts("Unique tags: #{tags_count}")
    IO.puts("\nTag distribution:")

    all_tags
    |> Enum.sort_by(fn {_tag, count} -> count end, :desc)
    |> Enum.each(fn {tag, count} ->
      IO.puts("  #{tag}: #{count}")
    end)

    demo_complete()
  end

  defp demo_complete do
    IO.puts("\n" <> String.duplicate("=", 70))
    IO.puts("DEMONSTRATION COMPLETE!")
    IO.puts(String.duplicate("=", 70) <> "\n")
    :ok
  end

  @doc """
  Quick demo showing just the key features.
  """
  @spec quick_demo() :: :ok
  def quick_demo do
    IO.puts("\n=== Quick ContactManager Demo ===\n")

    # Create and use sample database
    db = sample_database()

    IO.puts("1. Total contacts: #{map_size(db)}")

    IO.puts("\n2. VIP Contacts:")
    db |> ContactManager.search_by_tag(:vip) |> Formatter.format_summary_list() |> IO.puts()

    IO.puts("\n3. Work contacts sorted by name:")

    db
    |> ContactManager.list_contacts()
    |> Query.contains(:tags, :work)
    |> Query.sort_by(:name)
    |> Formatter.format_summary_list()
    |> IO.puts()

    IO.puts("\n=== Demo Complete ===\n")
    :ok
  end
end
