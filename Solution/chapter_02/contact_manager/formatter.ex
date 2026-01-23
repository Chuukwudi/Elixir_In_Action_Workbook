defmodule ContactManager.Formatter do
  @moduledoc """
  Provides formatting functions for contact data.

  This module handles various output formats including:
  - Human-readable text formatting
  - CSV export
  - List formatting
  """

  @doc """
  Formats a single contact for display.

  ## Parameters
    - contact: Map - The contact to format

  ## Returns
    - String - Formatted contact information

  ## Examples

      iex> contact = %{id: 1, name: "John Doe", email: "john@test.com", phone: "555-0100", tags: [:work], created_at: ~U[2024-01-01 12:00:00Z], notes: "CEO"}
      iex> ContactManager.Formatter.format_contact(contact)
      "ID: 1\\nName: John Doe\\nEmail: john@test.com\\nPhone: 555-0100\\nTags: work\\nCreated: 2024-01-01 12:00:00Z\\nNotes: CEO"
  """
  @spec format_contact(map()) :: String.t()
  def format_contact(%{} = contact) do
    """
    ID: #{contact.id}
    Name: #{contact.name}
    Email: #{contact.email}
    Phone: #{contact.phone}
    Tags: #{format_tags(contact.tags)}
    Created: #{format_datetime(contact.created_at)}
    Notes: #{contact.notes}
    """
    |> String.trim()
  end

  @doc """
  Formats a list of contacts for display.

  ## Parameters
    - contacts: List - List of contacts to format

  ## Returns
    - String - Formatted list of all contacts

  ## Examples

      iex> contacts = [%{id: 1, name: "Alice", ...}, %{id: 2, name: "Bob", ...}]
      iex> ContactManager.Formatter.format_list(contacts)
      "Total Contacts: 2\\n\\n=== Contact 1 ===\\n..."
  """
  @spec format_list(list(map())) :: String.t()
  def format_list(contacts) when is_list(contacts) do
    header = "Total Contacts: #{length(contacts)}\n\n"

    body =
      contacts
      |> Enum.with_index(1)
      |> Enum.map(fn {contact, index} ->
        "=== Contact #{index} ===\n#{format_contact(contact)}"
      end)
      |> Enum.join("\n\n")

    header <> body
  end

  @doc """
  Exports contacts to CSV format.

  ## Parameters
    - contacts: List - List of contacts to export

  ## Returns
    - String - CSV formatted data with headers

  ## Examples

      iex> contacts = [%{id: 1, name: "Alice", email: "alice@test.com", phone: "555-0100", tags: [:work], created_at: ~U[2024-01-01 12:00:00Z], notes: ""}]
      iex> ContactManager.Formatter.export_csv(contacts)
      "ID,Name,Email,Phone,Tags,Created,Notes\\n1,Alice,alice@test.com,555-0100,work,2024-01-01 12:00:00Z,\\"\\"\\n"
  """
  @spec export_csv(list(map())) :: String.t()
  def export_csv(contacts) when is_list(contacts) do
    header = "ID,Name,Email,Phone,Tags,Created,Notes\n"

    rows =
      contacts
      |> Enum.map(&contact_to_csv_row/1)
      |> Enum.join("\n")

    header <> rows <> "\n"
  end

  @doc """
  Formats a contact as a compact one-line summary.

  ## Parameters
    - contact: Map - The contact to format

  ## Returns
    - String - One-line summary

  ## Examples

      iex> contact = %{id: 1, name: "John Doe", email: "john@test.com", phone: "555-0100", tags: [:work]}
      iex> ContactManager.Formatter.format_summary(contact)
      "[1] John Doe <john@test.com> (555-0100) [work]"
  """
  @spec format_summary(map()) :: String.t()
  def format_summary(%{} = contact) do
    "[#{contact.id}] #{contact.name} <#{contact.email}> (#{contact.phone}) [#{format_tags(contact.tags)}]"
  end

  @doc """
  Formats a list of contacts as compact summaries.

  ## Parameters
    - contacts: List - List of contacts

  ## Returns
    - String - Multi-line summary list
  """
  @spec format_summary_list(list(map())) :: String.t()
  def format_summary_list(contacts) when is_list(contacts) do
    contacts
    |> Enum.map(&format_summary/1)
    |> Enum.join("\n")
  end

  # Private helper functions

  defp format_tags([]), do: "none"
  defp format_tags(tags) when is_list(tags) do
    tags
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(", ")
  end

  defp format_datetime(%DateTime{} = dt) do
    DateTime.to_string(dt)
  end

  defp contact_to_csv_row(contact) do
    [
      contact.id,
      escape_csv(contact.name),
      escape_csv(contact.email),
      escape_csv(contact.phone),
      format_tags(contact.tags),
      format_datetime(contact.created_at),
      escape_csv(contact.notes)
    ]
    |> Enum.join(",")
  end

  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end

  defp escape_csv(value), do: to_string(value)
end
