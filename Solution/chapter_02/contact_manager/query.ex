defmodule ContactManager.Query do
  @moduledoc """
  Advanced query and filtering operations for contacts.

  This module provides generic filtering, sorting, and grouping
  capabilities for contact collections.
  """

  @doc """
  Filters contacts by a specific field and value.

  ## Parameters
    - contacts: List - List of contacts to filter
    - field: Atom - The field to filter by
    - value: Any - The value to match

  ## Returns
    - List of matching contacts

  ## Examples

      iex> contacts = [%{name: "Alice", email: "alice@test.com"}, %{name: "Bob", email: "bob@test.com"}]
      iex> ContactManager.Query.filter_by(contacts, :name, "Alice")
      [%{name: "Alice", email: "alice@test.com"}]
  """
  @spec filter_by(list(map()), atom(), any()) :: list(map())
  def filter_by(contacts, field, value) when is_list(contacts) and is_atom(field) do
    Enum.filter(contacts, fn contact ->
      Map.get(contact, field) == value
    end)
  end

  @doc """
  Sorts contacts by a specific field.

  ## Parameters
    - contacts: List - List of contacts to sort
    - field: Atom - The field to sort by
    - direction: Atom - :asc or :desc (default: :asc)

  ## Returns
    - Sorted list of contacts

  ## Examples

      iex> contacts = [%{id: 2, name: "Bob"}, %{id: 1, name: "Alice"}]
      iex> ContactManager.Query.sort_by(contacts, :id)
      [%{id: 1, name: "Alice"}, %{id: 2, name: "Bob"}]

      iex> ContactManager.Query.sort_by(contacts, :name, :desc)
      [%{id: 2, name: "Bob"}, %{id: 1, name: "Alice"}]
  """
  @spec sort_by(list(map()), atom(), :asc | :desc) :: list(map())
  def sort_by(contacts, field, direction \\ :asc)
      when is_list(contacts) and is_atom(field) do
    sorted = Enum.sort_by(contacts, &Map.get(&1, field))

    case direction do
      :desc -> Enum.reverse(sorted)
      :asc -> sorted
    end
  end

  @doc """
  Groups contacts by their tags.

  ## Parameters
    - contacts: List - List of contacts to group

  ## Returns
    - Map of tag => list of contacts

  ## Examples

      iex> contacts = [
      ...>   %{id: 1, name: "Alice", tags: [:work, :vip]},
      ...>   %{id: 2, name: "Bob", tags: [:personal]},
      ...>   %{id: 3, name: "Charlie", tags: [:work]}
      ...> ]
      iex> grouped = ContactManager.Query.group_by_tag(contacts)
      iex> length(grouped[:work])
      2
  """
  @spec group_by_tag(list(map())) :: map()
  def group_by_tag(contacts) when is_list(contacts) do
    contacts
    |> Enum.reduce(%{}, fn contact, acc ->
      Enum.reduce(contact.tags, acc, fn tag, tag_acc ->
        Map.update(tag_acc, tag, [contact], fn existing ->
          [contact | existing]
        end)
      end)
    end)
    |> Enum.map(fn {tag, contacts} -> {tag, Enum.reverse(contacts)} end)
    |> Enum.into(%{})
  end

  @doc """
  Groups contacts by any field.

  ## Parameters
    - contacts: List - List of contacts to group
    - field: Atom - The field to group by

  ## Returns
    - Map of field_value => list of contacts

  ## Examples

      iex> contacts = [%{name: "Alice", email: "alice@work.com"}, %{name: "Bob", email: "bob@work.com"}]
      iex> grouped = ContactManager.Query.group_by(contacts, :email)
      iex> Map.keys(grouped)
      ["alice@work.com", "bob@work.com"]
  """
  @spec group_by(list(map()), atom()) :: map()
  def group_by(contacts, field) when is_list(contacts) and is_atom(field) do
    Enum.group_by(contacts, &Map.get(&1, field))
  end

  @doc """
  Finds contacts matching multiple criteria.

  ## Parameters
    - contacts: List - List of contacts to search
    - criteria: Map - Field => value pairs to match

  ## Returns
    - List of contacts matching all criteria

  ## Examples

      iex> contacts = [
      ...>   %{name: "Alice", email: "alice@work.com", tags: [:work]},
      ...>   %{name: "Alice", email: "alice@home.com", tags: [:personal]}
      ...> ]
      iex> ContactManager.Query.search(contacts, %{name: "Alice", email: "alice@work.com"})
      [%{name: "Alice", email: "alice@work.com", tags: [:work]}]
  """
  @spec search(list(map()), map()) :: list(map())
  def search(contacts, criteria) when is_list(contacts) and is_map(criteria) do
    Enum.filter(contacts, fn contact ->
      Enum.all?(criteria, fn {field, value} ->
        Map.get(contact, field) == value
      end)
    end)
  end

  @doc """
  Finds contacts where a field contains a value (for list fields like tags).

  ## Parameters
    - contacts: List - List of contacts to search
    - field: Atom - The field to check (should be a list field)
    - value: Any - The value to look for in the list

  ## Returns
    - List of contacts where field contains value

  ## Examples

      iex> contacts = [
      ...>   %{name: "Alice", tags: [:work, :vip]},
      ...>   %{name: "Bob", tags: [:personal]}
      ...> ]
      iex> ContactManager.Query.contains(contacts, :tags, :vip)
      [%{name: "Alice", tags: [:work, :vip]}]
  """
  @spec contains(list(map()), atom(), any()) :: list(map())
  def contains(contacts, field, value) when is_list(contacts) and is_atom(field) do
    Enum.filter(contacts, fn contact ->
      field_value = Map.get(contact, field)
      is_list(field_value) and value in field_value
    end)
  end

  @doc """
  Paginates a list of contacts.

  ## Parameters
    - contacts: List - List of contacts to paginate
    - page: Integer - Page number (1-indexed)
    - per_page: Integer - Number of items per page

  ## Returns
    - Tuple of {items, total_pages}

  ## Examples

      iex> contacts = Enum.map(1..25, fn i -> %{id: i, name: "Contact \#{i}"} end)
      iex> {page_items, total_pages} = ContactManager.Query.paginate(contacts, 1, 10)
      iex> {length(page_items), total_pages}
      {10, 3}
  """
  @spec paginate(list(map()), pos_integer(), pos_integer()) :: {list(map()), pos_integer()}
  def paginate(contacts, page, per_page)
      when is_list(contacts) and is_integer(page) and is_integer(per_page) and page > 0 and
             per_page > 0 do
    total = length(contacts)
    total_pages = ceil(total / per_page)

    offset = (page - 1) * per_page

    items =
      contacts
      |> Enum.drop(offset)
      |> Enum.take(per_page)

    {items, total_pages}
  end

  @doc """
  Counts contacts by a specific field value.

  ## Parameters
    - contacts: List - List of contacts
    - field: Atom - The field to count by

  ## Returns
    - Map of field_value => count

  ## Examples

      iex> contacts = [%{tags: [:work]}, %{tags: [:work]}, %{tags: [:personal]}]
      iex> ContactManager.Query.count_by(contacts, :tags)
      # Note: This counts individual tag occurrences
  """
  @spec count_by(list(map()), atom()) :: map()
  def count_by(contacts, field) when is_list(contacts) and is_atom(field) do
    contacts
    |> Enum.map(&Map.get(&1, field))
    |> Enum.frequencies()
  end

  @doc """
  Finds the top N contacts by a field (assumes numeric field).

  ## Parameters
    - contacts: List - List of contacts
    - field: Atom - The field to sort by
    - n: Integer - Number of top results to return

  ## Returns
    - List of top N contacts

  ## Examples

      iex> contacts = [%{id: 1, score: 85}, %{id: 2, score: 95}, %{id: 3, score: 75}]
      iex> ContactManager.Query.top_n(contacts, :score, 2)
      [%{id: 2, score: 95}, %{id: 1, score: 85}]
  """
  @spec top_n(list(map()), atom(), pos_integer()) :: list(map())
  def top_n(contacts, field, n) when is_list(contacts) and is_atom(field) and is_integer(n) do
    contacts
    |> sort_by(field, :desc)
    |> Enum.take(n)
  end
end
