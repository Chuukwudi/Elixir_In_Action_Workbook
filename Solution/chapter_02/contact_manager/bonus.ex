defmodule ContactManager.Bonus do
  @moduledoc """
  Bonus features including CSV import, JSON export, batch operations,
  and statistics.
  """

  alias ContactManager.{Query, Formatter}

  # ============================================================================
  # IMPORT/EXPORT
  # ============================================================================

  @doc """
  Imports contacts from CSV data.

  ## Parameters
    - csv_data: String - CSV formatted data with header row
    - opts: Keyword list
      - :validate - Whether to validate contacts (default: true)
      - :skip_invalid - Skip invalid rows instead of failing (default: false)

  ## Returns
    - `{:ok, contacts}` - Successfully parsed contacts
    - `{:error, reason}` - Parse failed

  ## CSV Format
  ```
  ID,Name,Email,Phone,Tags,Created,Notes
  1,Alice,alice@test.com,555-0100,work;vip,2024-01-01T12:00:00Z,CEO
  ```
  """
  @spec import_csv(String.t(), keyword()) :: {:ok, list(map())} | {:error, String.t()}
  def import_csv(csv_data, opts \\ []) do
    validate? = Keyword.get(opts, :validate, true)
    skip_invalid? = Keyword.get(opts, :skip_invalid, false)

    csv_data
    |> String.split("\n", trim: true)
    |> parse_csv_rows()
    |> process_csv_contacts(validate?, skip_invalid?)
  end

  defp parse_csv_rows([header | rows]) do
    header_fields = parse_csv_line(header)

    Enum.map(rows, fn row ->
      values = parse_csv_line(row)
      Enum.zip(header_fields, values) |> Enum.into(%{})
    end)
  end

  defp parse_csv_rows([]), do: []

  defp parse_csv_line(line) do
    # Simple CSV parser (doesn't handle all edge cases)
    line
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&unescape_csv/1)
  end

  defp unescape_csv("\"" <> rest) do
    rest
    |> String.trim_trailing("\"")
    |> String.replace("\"\"", "\"")
  end

  defp unescape_csv(value), do: value

  defp process_csv_contacts(csv_rows, validate?, skip_invalid?) do
    results =
      Enum.map(csv_rows, fn row ->
        csv_row_to_contact(row, validate?)
      end)

    if skip_invalid? do
      contacts = Enum.filter(results, &match?({:ok, _}, &1)) |> Enum.map(fn {:ok, c} -> c end)
      {:ok, contacts}
    else
      case Enum.find(results, &match?({:error, _}, &1)) do
        nil ->
          contacts = Enum.map(results, fn {:ok, c} -> c end)
          {:ok, contacts}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp csv_row_to_contact(row, validate?) do
    try do
      contact = %{
        id: parse_csv_id(row["ID"]),
        name: row["Name"] || "",
        email: row["Email"] || "",
        phone: row["Phone"] || "",
        tags: parse_csv_tags(row["Tags"]),
        created_at: parse_csv_datetime(row["Created"]),
        notes: row["Notes"] || ""
      }

      if validate? do
        case ContactManager.create_contact(contact.name, contact.email, contact.phone,
               tags: contact.tags,
               notes: contact.notes
             ) do
          {:ok, validated} -> {:ok, Map.put(validated, :id, contact.id)}
          {:error, reason} -> {:error, "Row #{contact.id}: #{reason}"}
        end
      else
        {:ok, contact}
      end
    rescue
      e -> {:error, "Parse error: #{Exception.message(e)}"}
    end
  end

  defp parse_csv_id(id_str) when is_binary(id_str) do
    String.to_integer(id_str)
  end

  defp parse_csv_tags(nil), do: []
  defp parse_csv_tags(""), do: []

  defp parse_csv_tags(tags_str) do
    tags_str
    |> String.split(";", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp parse_csv_datetime(dt_str) when is_binary(dt_str) do
    case DateTime.from_iso8601(dt_str) do
      {:ok, dt, _offset} -> dt
      _ -> DateTime.utc_now()
    end
  end

  @doc """
  Exports contacts to JSON format.

  ## Parameters
    - contacts: List - Contacts to export
    - opts: Keyword list
      - :pretty - Pretty print JSON (default: false)

  ## Returns
    - String - JSON formatted data
  """
  @spec export_json(list(map()), keyword()) :: String.t()
  def export_json(contacts, opts \\ []) do
    pretty? = Keyword.get(opts, :pretty, false)

    # Convert DateTime to ISO8601 strings for JSON
    json_contacts =
      Enum.map(contacts, fn contact ->
        Map.update!(contact, :created_at, &DateTime.to_iso8601/1)
      end)

    encoded =
      if pretty? do
        Jason.encode!(json_contacts, pretty: true)
      else
        Jason.encode!(json_contacts)
      end

    encoded
  rescue
    UndefinedFunctionError ->
      # Fallback if Jason not available
      simple_json_encode(contacts)
  end

  # Simple JSON encoder (basic implementation)
  defp simple_json_encode(contacts) do
    items =
      Enum.map(contacts, fn contact ->
        fields = [
          ~s("id": #{contact.id}),
          ~s("name": "#{escape_json(contact.name)}"),
          ~s("email": "#{escape_json(contact.email)}"),
          ~s("phone": "#{escape_json(contact.phone)}"),
          ~s("tags": [#{Enum.map_join(contact.tags, ", ", &~s("#{&1}"))}]),
          ~s("created_at": "#{DateTime.to_iso8601(contact.created_at)}"),
          ~s("notes": "#{escape_json(contact.notes)}")
        ]

        "{" <> Enum.join(fields, ", ") <> "}"
      end)

    "[" <> Enum.join(items, ", ") <> "]"
  end

  defp escape_json(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
  end

  # ============================================================================
  # ADVANCED QUERIES
  # ============================================================================

  @doc """
  Searches contacts using a mini query DSL.

  ## Parameters
    - contacts: List - Contacts to search
    - query: Map - Query criteria

  ## Supported Criteria
    - Field equality: `%{name: "Alice"}`
    - Tag containment: `%{tag: :work}`
    - Multiple criteria: All must match (AND)

  ## Examples

      iex> search(contacts, %{name: "Alice", tag: :work})
      [%{name: "Alice", tags: [:work, :vip], ...}]
  """
  @spec search(list(map()), map()) :: list(map())
  def search(contacts, query) when is_map(query) do
    Enum.filter(contacts, fn contact ->
      Enum.all?(query, fn
        {:tag, tag} -> tag in contact.tags
        {field, value} -> Map.get(contact, field) == value
      end)
    end)
  end

  # ============================================================================
  # BATCH OPERATIONS
  # ============================================================================

  @doc """
  Creates multiple contacts in batch.

  ## Parameters
    - contact_data: List - List of {name, email, phone, opts} tuples

  ## Returns
    - `{:ok, {contacts, errors}}` - Created contacts and any errors
  """
  @spec bulk_create(list({String.t(), String.t(), String.t(), keyword()})) ::
          {:ok, {list(map()), list({integer(), String.t()})}}
  def bulk_create(contact_data) do
    results =
      contact_data
      |> Enum.with_index()
      |> Enum.map(fn {{name, email, phone, opts}, index} ->
        {index, ContactManager.create_contact(name, email, phone, opts)}
      end)

    contacts =
      results
      |> Enum.filter(fn {_i, result} -> match?({:ok, _}, result) end)
      |> Enum.map(fn {_i, {:ok, contact}} -> contact end)

    errors =
      results
      |> Enum.filter(fn {_i, result} -> match?({:error, _}, result) end)
      |> Enum.map(fn {i, {:error, reason}} -> {i, reason} end)

    {:ok, {contacts, errors}}
  end

  @doc """
  Updates multiple contacts with the same fields.

  ## Parameters
    - db: Map - Contact database
    - ids: List - Contact IDs to update
    - fields: Map - Fields to update

  ## Returns
    - `{:ok, {new_db, updated, failed}}` - Results of updates
  """
  @spec bulk_update(map(), list(integer()), map()) ::
          {:ok, {map(), list(map()), list({integer(), String.t()})}}
  def bulk_update(db, ids, fields) do
    results =
      Enum.reduce(ids, {db, [], []}, fn id, {current_db, updated, failed} ->
        case ContactManager.update_contact(current_db, id, fields) do
          {:ok, {new_db, contact}} ->
            {new_db, [contact | updated], failed}

          {:error, reason} ->
            {current_db, updated, [{id, reason} | failed]}
        end
      end)

    {final_db, updated, failed} = results
    {:ok, {final_db, Enum.reverse(updated), Enum.reverse(failed)}}
  end

  @doc """
  Adds a tag to multiple contacts.

  ## Parameters
    - db: Map - Contact database
    - ids: List - Contact IDs
    - tag: Atom - Tag to add

  ## Returns
    - `{:ok, {new_db, count}}` - Updated database and count of modified contacts
  """
  @spec bulk_tag(map(), list(integer()), atom()) :: {:ok, {map(), integer()}}
  def bulk_tag(db, ids, tag) when is_atom(tag) do
    {final_db, count} =
      Enum.reduce(ids, {db, 0}, fn id, {current_db, count} ->
        case ContactManager.get_contact(current_db, id) do
          {:ok, contact} ->
            new_tags = Enum.uniq([tag | contact.tags])

            case ContactManager.update_contact(current_db, id, %{tags: new_tags}) do
              {:ok, {new_db, _}} -> {new_db, count + 1}
              _ -> {current_db, count}
            end

          _ ->
            {current_db, count}
        end
      end)

    {:ok, {final_db, count}}
  end

  # ============================================================================
  # STATISTICS
  # ============================================================================

  @doc """
  Calculates comprehensive statistics about contacts.

  ## Returns
    - Map containing various statistics
  """
  @spec stats(map()) :: map()
  def stats(db) when is_map(db) do
    contacts = ContactManager.list_contacts(db)

    tag_freq =
      contacts
      |> Enum.flat_map(& &1.tags)
      |> Enum.frequencies()

    %{
      total_contacts: length(contacts),
      total_tags: map_size(tag_freq),
      tags_distribution: tag_freq,
      contacts_per_tag: contacts_per_tag_stats(contacts),
      most_common_tag: most_common(tag_freq),
      contacts_with_notes: count_with_notes(contacts),
      average_tags_per_contact: average_tags(contacts),
      recent_contacts: recent_contacts_count(contacts, 30)
    }
  end

  defp contacts_per_tag_stats(contacts) do
    contacts
    |> Query.group_by_tag()
    |> Enum.map(fn {tag, tag_contacts} -> {tag, length(tag_contacts)} end)
    |> Enum.into(%{})
  end

  defp most_common(frequencies) when map_size(frequencies) == 0, do: nil

  defp most_common(frequencies) do
    Enum.max_by(frequencies, fn {_tag, count} -> count end)
  end

  defp count_with_notes(contacts) do
    Enum.count(contacts, fn contact ->
      contact.notes != "" and not is_nil(contact.notes)
    end)
  end

  defp average_tags(contacts) when length(contacts) == 0, do: 0.0

  defp average_tags(contacts) do
    total_tags =
      contacts
      |> Enum.map(&length(&1.tags))
      |> Enum.sum()

    total_tags / length(contacts)
  end

  defp recent_contacts_count(contacts, days) do
    cutoff = DateTime.add(DateTime.utc_now(), -days * 24 * 60 * 60, :second)

    Enum.count(contacts, fn contact ->
      DateTime.compare(contact.created_at, cutoff) == :gt
    end)
  end

  @doc """
  Generates a statistics report.

  ## Parameters
    - db: Map - Contact database

  ## Returns
    - String - Formatted statistics report
  """
  @spec stats_report(map()) :: String.t()
  def stats_report(db) do
    statistics = stats(db)

    """
    ═══════════════════════════════════════
    CONTACT DATABASE STATISTICS
    ═══════════════════════════════════════

    Total Contacts: #{statistics.total_contacts}
    Total Unique Tags: #{statistics.total_tags}
    Contacts with Notes: #{statistics.contacts_with_notes}
    Average Tags per Contact: #{Float.round(statistics.average_tags_per_contact, 2)}
    New Contacts (last 30 days): #{statistics.recent_contacts}

    TAG DISTRIBUTION
    ───────────────────────────────────────
    #{format_tag_distribution(statistics.tags_distribution)}

    MOST COMMON TAG
    ───────────────────────────────────────
    #{format_most_common(statistics.most_common_tag)}

    CONTACTS PER TAG
    ───────────────────────────────────────
    #{format_contacts_per_tag(statistics.contacts_per_tag)}
    """
    |> String.trim()
  end

  defp format_tag_distribution(dist) do
    dist
    |> Enum.sort_by(fn {_tag, count} -> count end, :desc)
    |> Enum.map(fn {tag, count} ->
      bar = String.duplicate("█", min(count, 50))
      "#{tag |> to_string() |> String.pad_trailing(15)}: #{bar} (#{count})"
    end)
    |> Enum.join("\n")
  end

  defp format_most_common(nil), do: "No tags"

  defp format_most_common({tag, count}) do
    "#{tag} (#{count} contacts)"
  end

  defp format_contacts_per_tag(cpt) do
    cpt
    |> Enum.sort_by(fn {_tag, count} -> count end, :desc)
    |> Enum.map(fn {tag, count} -> "#{tag}: #{count}" end)
    |> Enum.join(", ")
  end
end
