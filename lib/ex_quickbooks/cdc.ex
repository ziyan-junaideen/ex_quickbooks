defmodule ExQuickbooks.CDC do
  @moduledoc """
  Change Data Capture helpers for incremental QuickBooks synchronization.
  """

  @supported_entity_names %{
    "account" => "Account",
    "accounts" => "Account",
    "customer" => "Customer",
    "customers" => "Customer",
    "invoice" => "Invoice",
    "invoices" => "Invoice",
    "item" => "Item",
    "items" => "Item",
    "payment" => "Payment",
    "payments" => "Payment",
    "vendor" => "Vendor",
    "vendors" => "Vendor"
  }

  @type entity_group :: %{
          records: [map()],
          deleted_ids: [map()]
        }

  @type grouped_changes :: %{
          optional(String.t()) => entity_group()
        }

  @doc """
  Returns the currently supported CDC entity names.
  """
  @spec supported_entity_names() :: [String.t()]
  def supported_entity_names do
    @supported_entity_names
    |> Map.values()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Fetches grouped CDC changes since the given checkpoint.
  """
  @spec fetch(
          ExQuickbooks.Client.t(),
          [String.t() | atom()] | String.t() | atom(),
          String.t() | DateTime.t(),
          keyword()
        ) ::
          {:ok, grouped_changes()} | {:error, ExQuickbooks.Error.t()}
  def fetch(client, entity_names, changed_since, options \\ []) do
    with {:ok, normalized_entity_names} <- normalize_entity_names(entity_names),
         {:ok, normalized_changed_since} <- normalize_changed_since(changed_since),
         {:ok, cdc_response} <-
           request_changes(client, normalized_entity_names, normalized_changed_since, options),
         {:ok, grouped_changes} <- group_changes(cdc_response) do
      {:ok, ensure_requested_entities(grouped_changes, normalized_entity_names)}
    end
  end

  @doc """
  Groups a CDC response by entity name and preserves deleted IDs per entity.
  """
  @spec group_changes([map()] | map()) ::
          {:ok, grouped_changes()} | {:error, ExQuickbooks.Error.t()}
  def group_changes(%{"CDCResponse" => cdc_response}) do
    group_changes(cdc_response)
  end

  def group_changes(cdc_response) when is_list(cdc_response) do
    grouped_changes =
      Enum.reduce(cdc_response, %{}, fn change_group, grouped_changes ->
        merge_change_group(grouped_changes, change_group)
      end)

    {:ok, grouped_changes}
  end

  def group_changes(cdc_response) do
    {:error,
     ExQuickbooks.Error.new(:api_error,
       message: "CDC response did not contain grouped entity changes",
       details: %{"cdc_response" => cdc_response}
     )}
  end

  defp request_changes(client, normalized_entity_names, normalized_changed_since, options) do
    cdc_request =
      ExQuickbooks.Request.cdc(
        normalized_entity_names,
        normalized_changed_since,
        response_path: ["CDCResponse"]
      )

    ExQuickbooks.request(client, cdc_request, request_options(options))
  end

  defp merge_change_group(grouped_changes, %{} = change_group) do
    grouped_changes
    |> merge_direct_entity_records(change_group)
    |> merge_query_response_groups(change_group)
    |> merge_deleted_ids(Map.get(change_group, "DeletedId", []))
  end

  defp merge_change_group(grouped_changes, _invalid_group), do: grouped_changes

  defp merge_direct_entity_records(grouped_changes, change_group) do
    Enum.reduce(change_group, grouped_changes, fn {entity_name, records}, grouped_changes ->
      case direct_entity_records(entity_name, records) do
        {:ok, entity_records} ->
          append_records_to_entity_group(grouped_changes, entity_name, entity_records)

        :ignore ->
          grouped_changes
      end
    end)
  end

  defp merge_query_response_groups(grouped_changes, change_group) do
    case Map.get(change_group, "QueryResponse") do
      query_response_groups when is_list(query_response_groups) ->
        Enum.reduce(query_response_groups, grouped_changes, &merge_direct_entity_records(&2, &1))

      _no_query_response_groups ->
        grouped_changes
    end
  end

  defp merge_deleted_ids(grouped_changes, deleted_ids) when is_list(deleted_ids) do
    Enum.reduce(deleted_ids, grouped_changes, fn deleted_id, grouped_changes ->
      case deleted_entity_name(deleted_id) do
        {:ok, normalized_deleted_entity_name} ->
          append_deleted_id_to_entity_group(
            grouped_changes,
            normalized_deleted_entity_name,
            deleted_id
          )

        :ignore ->
          grouped_changes
      end
    end)
  end

  defp merge_deleted_ids(grouped_changes, _deleted_ids), do: grouped_changes

  defp update_entity_group(grouped_changes, entity_name, update_function) do
    current_entity_group = Map.get(grouped_changes, entity_name, empty_entity_group())
    updated_entity_group = update_function.(current_entity_group)

    Map.put(grouped_changes, entity_name, updated_entity_group)
  end

  defp append_records_to_entity_group(grouped_changes, entity_name, entity_records) do
    update_entity_group(grouped_changes, entity_name, fn entity_group ->
      %{entity_group | records: entity_group.records ++ entity_records}
    end)
  end

  defp append_deleted_id_to_entity_group(grouped_changes, entity_name, deleted_id) do
    update_entity_group(grouped_changes, entity_name, fn entity_group ->
      %{entity_group | deleted_ids: entity_group.deleted_ids ++ [deleted_id]}
    end)
  end

  defp ensure_requested_entities(grouped_changes, normalized_entity_names) do
    Enum.reduce(normalized_entity_names, grouped_changes, fn entity_name, grouped_changes ->
      Map.put_new(grouped_changes, entity_name, empty_entity_group())
    end)
  end

  defp empty_entity_group do
    %{
      records: [],
      deleted_ids: []
    }
  end

  defp normalize_entity_names(entity_names) do
    listed_entity_names = List.wrap(entity_names)

    case listed_entity_names do
      [] ->
        {:error,
         ExQuickbooks.Error.validation_failed(
           "entity_names must include at least one supported entity"
         )}

      _non_empty_entity_names ->
        normalize_listed_entity_names(listed_entity_names)
    end
  end

  defp normalize_entity_name(entity_name) when is_atom(entity_name) do
    entity_name
    |> to_string()
    |> normalize_entity_name()
  end

  defp normalize_entity_name(entity_name) when is_binary(entity_name) do
    normalized_entity_key =
      entity_name
      |> String.trim()
      |> String.downcase()

    case Map.fetch(@supported_entity_names, normalized_entity_key) do
      {:ok, normalized_entity_name} ->
        {:ok, normalized_entity_name}

      :error ->
        {:error,
         ExQuickbooks.Error.validation_failed(
           "unsupported CDC entity #{inspect(entity_name)}",
           %{supported_entities: supported_entity_names()}
         )}
    end
  end

  defp normalize_entity_name(entity_name) do
    {:error,
     ExQuickbooks.Error.validation_failed(
       "unsupported CDC entity #{inspect(entity_name)}",
       %{supported_entities: supported_entity_names()}
     )}
  end

  defp normalize_changed_since(%DateTime{} = changed_since) do
    {:ok, DateTime.to_iso8601(changed_since)}
  end

  defp normalize_changed_since(changed_since) when is_binary(changed_since) do
    case DateTime.from_iso8601(changed_since) do
      {:ok, parsed_changed_since, _utc_offset} ->
        {:ok, DateTime.to_iso8601(parsed_changed_since)}

      {:error, _reason} ->
        {:error,
         ExQuickbooks.Error.validation_failed(
           "changed_since must be an ISO8601 timestamp with timezone"
         )}
    end
  end

  defp normalize_changed_since(_changed_since) do
    {:error,
     ExQuickbooks.Error.validation_failed(
       "changed_since must be an ISO8601 timestamp or DateTime"
     )}
  end

  defp request_options(options) do
    Keyword.take(options, [:base_url, :max_retries, :sleep_function])
  end

  defp direct_entity_records(entity_name, records) do
    cond do
      entity_name in ["DeletedId", "QueryResponse"] ->
        :ignore

      is_list(records) ->
        {:ok, records}

      true ->
        :ignore
    end
  end

  defp deleted_entity_name(deleted_id) do
    case Map.get(deleted_id, "Type") do
      deleted_entity_name when is_binary(deleted_entity_name) ->
        {:ok, deleted_entity_name}

      _missing_type ->
        :ignore
    end
  end

  defp normalize_listed_entity_names(listed_entity_names) do
    case Enum.reduce_while(listed_entity_names, {:ok, []}, &reduce_entity_name/2) do
      {:ok, normalized_entity_names} ->
        {:ok, Enum.uniq(normalized_entity_names)}

      {:error, _reason} = error ->
        error
    end
  end

  defp reduce_entity_name(entity_name, {:ok, normalized_entity_names}) do
    case normalize_entity_name(entity_name) do
      {:ok, normalized_entity_name} ->
        {:cont, {:ok, normalized_entity_names ++ [normalized_entity_name]}}

      {:error, _reason} = error ->
        {:halt, error}
    end
  end
end
