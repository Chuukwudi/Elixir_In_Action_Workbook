defmodule ContactManager do
  @moduledoc """
  A contact management system demonstrating Elixir's data structures,
  pattern matching, and functional programming principles.

  This module manages contacts stored as maps, providing CRUD operations
  and search functionality while maintaining immutability.

  ## Examples

      iex> {:ok, contact} = ContactManager.create_contact("John Doe", "john@example.com", "555-0100")
      iex> contact.name
      "John Doe"

      iex> {:ok, contact} = ContactManager.create_contact("Jane Smith", "jane@example.com", "555-0101", tags: [:work, :vip])
      iex> contact.tags
      [:work, :vip]
  """

  # Using module attribute as a "constant" for the contacts store
  # In a real app, this would be in a database or process state
  @initial_state %{contacts: %{}, next_id: 1}

  @doc """
  Creates a new contact with the given information.

  ## Parameters
    - name: String - The contact's full name
    - email: String - The contact's email address
    - phone: String - The contact's phone number
    - opts: Keyword list - Optional parameters
      - :tags - List of atoms (default: [])
      - :notes - String (default: "")

  ## Returns
    - `{:ok, contact}` - Successfully created contact
    - `{:error, reason}` - Validation failed

  ## Examples

      iex> ContactManager.create_contact("Alice", "alice@test.com", "555-1234")
      {:ok, %{id: 1, name: "Alice", email: "alice@test.com", ...}}

      iex> ContactManager.create_contact("", "invalid", "123")
      {:error, "Name cannot be empty"}
  """
  @spec create_contact(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, String.t()}
  def create_contact(name, email, phone, opts \\ []) do
    tags = Keyword.get(opts, :tags, [])
    notes = Keyword.get(opts, :notes, "")

    contact = %{
      id: generate_id(),
      name: normalize_name(name),
      email: email,
      phone: phone,
      tags: tags,
      created_at: DateTime.utc_now(),
      notes: notes
    }

    case validate_contact(contact) do
      :ok -> {:ok, contact}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Retrieves a contact by ID from the given contact list.

  ## Parameters
    - contacts: Map - The contacts database
    - id: Integer - The contact ID to retrieve

  ## Returns
    - `{:ok, contact}` - Contact found
    - `{:error, :not_found}` - Contact not found
  """
  @spec get_contact(map(), integer()) :: {:ok, map()} | {:error, :not_found}
  def get_contact(contacts, id) when is_map(contacts) do
    case Map.fetch(contacts, id) do
      {:ok, contact} -> {:ok, contact}
      :error -> {:error, :not_found}
    end
  end

  @doc """
  Lists all contacts from the database.

  ## Parameters
    - contacts: Map - The contacts database

  ## Returns
    - List of all contacts
  """
  @spec list_contacts(map()) :: list(map())
  def list_contacts(contacts) when is_map(contacts) do
    contacts
    |> Map.values()
    |> Enum.sort_by(& &1.id)
  end

  @doc """
  Updates a contact with new field values.

  ## Parameters
    - contacts: Map - The contacts database
    - id: Integer - The contact ID to update
    - fields: Map or Keyword list - Fields to update

  ## Returns
    - `{:ok, {updated_contacts, updated_contact}}` - Successfully updated
    - `{:error, reason}` - Update failed

  ## Examples

      iex> contacts = %{1 => %{id: 1, name: "John", email: "john@test.com", ...}}
      iex> {:ok, {new_contacts, updated}} = ContactManager.update_contact(contacts, 1, %{name: "John Doe"})
      iex> updated.name
      "John Doe"
  """
  @spec update_contact(map(), integer(), map() | keyword()) ::
          {:ok, {map(), map()}} | {:error, atom() | String.t()}
  def update_contact(contacts, id, fields) when is_map(contacts) do
    case get_contact(contacts, id) do
      {:ok, contact} ->
        # Convert keyword list to map if necessary
        fields_map = if is_list(fields), do: Enum.into(fields, %{}), else: fields

        # Merge fields but preserve id and created_at
        updated_contact =
          contact
          |> Map.merge(fields_map)
          |> Map.put(:id, contact.id)
          |> Map.put(:created_at, contact.created_at)

        case validate_contact(updated_contact) do
          :ok ->
            new_contacts = Map.put(contacts, id, updated_contact)
            {:ok, {new_contacts, updated_contact}}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc """
  Deletes a contact by ID.

  ## Parameters
    - contacts: Map - The contacts database
    - id: Integer - The contact ID to delete

  ## Returns
    - `{:ok, {updated_contacts, deleted_contact}}` - Successfully deleted
    - `{:error, :not_found}` - Contact not found
  """
  @spec delete_contact(map(), integer()) :: {:ok, {map(), map()}} | {:error, :not_found}
  def delete_contact(contacts, id) when is_map(contacts) do
    case get_contact(contacts, id) do
      {:ok, contact} ->
        new_contacts = Map.delete(contacts, id)
        {:ok, {new_contacts, contact}}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  @doc """
  Searches for contacts with a specific tag.

  ## Parameters
    - contacts: Map - The contacts database
    - tag: Atom - The tag to search for

  ## Returns
    - List of contacts with the given tag
  """
  @spec search_by_tag(map(), atom()) :: list(map())
  def search_by_tag(contacts, tag) when is_map(contacts) and is_atom(tag) do
    contacts
    |> Map.values()
    |> Enum.filter(fn contact -> tag in contact.tags end)
  end

  @doc """
  Searches for contacts by partial name match (case-insensitive).

  ## Parameters
    - contacts: Map - The contacts database
    - partial_name: String - The partial name to search for

  ## Returns
    - List of contacts whose name contains the partial name
  """
  @spec search_by_name(map(), String.t()) :: list(map())
  def search_by_name(contacts, partial_name) when is_map(contacts) and is_binary(partial_name) do
    lowercase_search = String.downcase(partial_name)

    contacts
    |> Map.values()
    |> Enum.filter(fn contact ->
      contact.name
      |> String.downcase()
      |> String.contains?(lowercase_search)
    end)
  end

  # Private Helper Functions

  @spec validate_contact(map()) :: :ok | {:error, String.t()}
  defp validate_contact(%{name: name, email: email, phone: phone} = _contact) do
    cond do
      String.trim(name) == "" ->
        {:error, "Name cannot be empty"}

      not validate_email(email) ->
        {:error, "Invalid email format"}

      String.trim(phone) == "" ->
        {:error, "Phone cannot be empty"}

      true ->
        :ok
    end
  end

  defp validate_contact(_), do: {:error, "Invalid contact structure"}

  @spec validate_email(String.t()) :: boolean()
  defp validate_email(email) do
    # Basic email validation: contains @ and at least one character on each side
    email_regex = ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
    String.match?(email, email_regex)
  end

  @spec generate_id() :: integer()
  defp generate_id do
    # In a real app, this would use a proper ID generation strategy
    # For this demo, we'll use timestamp + random number
    :erlang.unique_integer([:positive])
  end

  @spec normalize_name(String.t()) :: String.t()
  defp normalize_name(name) do
    name
    |> String.trim()
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Creates an empty contact database.

  ## Returns
    - Empty map to store contacts
  """
  @spec new() :: map()
  def new, do: %{}

  @doc """
  Adds a contact to the database.

  ## Parameters
    - contacts: Map - The contacts database
    - contact: Map - The contact to add

  ## Returns
    - Updated contacts map
  """
  @spec add(map(), map()) :: map()
  def add(contacts, %{id: id} = contact) when is_map(contacts) do
    Map.put(contacts, id, contact)
  end
end
