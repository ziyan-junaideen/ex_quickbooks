defmodule ExQuickbooks.Query do
  @moduledoc """
  Generic query helpers for QuickBooks Online.

  The query helper accepts raw QuickBooks query statements and optionally
  appends `STARTPOSITION` / `MAXRESULTS` clauses for caller-driven pagination.
  """

  @pagination_schema [
    start_position: [type: :pos_integer],
    max_results: [type: :pos_integer]
  ]

  @doc """
  Runs a raw QuickBooks query statement.

  When `:start_position` or `:max_results` are provided, the helper appends the
  matching `STARTPOSITION` and `MAXRESULTS` clauses unless the statement
  already includes them.
  """
  @spec run(ExQuickbooks.Client.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, ExQuickbooks.Error.t()}
  def run(client, statement, options \\ []) when is_binary(statement) do
    pagination_options = Keyword.take(options, [:start_position, :max_results])

    with {:ok, validated_pagination_options} <-
           validate_pagination_options(pagination_options) do
      statement = build_statement(statement, validated_pagination_options)

      query_request =
        ExQuickbooks.Request.query(
          statement,
          response_path: ["QueryResponse"]
        )

      ExQuickbooks.request(client, query_request, request_options(options))
    end
  end

  @doc """
  Extracts the primary top-level collection from a `QueryResponse` payload.

  ## Examples

      iex> ExQuickbooks.Query.top_level_collection(%{
      ...>   "Customer" => [%{"Id" => "123"}],
      ...>   "startPosition" => 1,
      ...>   "maxResults" => 1
      ...> })
      {:ok, {"Customer", [%{"Id" => "123"}]}}
  """
  @spec top_level_collection(map()) ::
          {:ok, {String.t(), list()}} | {:error, ExQuickbooks.Error.t()}
  def top_level_collection(query_response) when is_map(query_response) do
    case Enum.find(query_response, &top_level_collection_entry?/1) do
      {collection_name, collection_entries} ->
        {:ok, {collection_name, collection_entries}}

      nil ->
        {:error,
         ExQuickbooks.Error.new(:api_error,
           message: "Query response did not contain a top-level collection",
           details: query_response
         )}
    end
  end

  defp build_statement(statement, validated_pagination_options) do
    statement
    |> String.trim()
    |> maybe_append_start_position(validated_pagination_options[:start_position])
    |> maybe_append_max_results(validated_pagination_options[:max_results])
  end

  defp maybe_append_start_position(statement, nil), do: statement

  defp maybe_append_start_position(statement, start_position) do
    if String.match?(statement, ~r/\bSTARTPOSITION\b/i) do
      statement
    else
      statement <> " STARTPOSITION " <> Integer.to_string(start_position)
    end
  end

  defp maybe_append_max_results(statement, nil), do: statement

  defp maybe_append_max_results(statement, max_results) do
    if String.match?(statement, ~r/\bMAXRESULTS\b/i) do
      statement
    else
      statement <> " MAXRESULTS " <> Integer.to_string(max_results)
    end
  end

  defp top_level_collection_entry?({_collection_name, collection_entries})
       when is_list(collection_entries),
       do: true

  defp top_level_collection_entry?(_entry), do: false

  defp request_options(options) do
    Keyword.take(options, [:base_url, :max_retries, :sleep_function])
  end

  defp validate_pagination_options(options) do
    case NimbleOptions.validate(options, @pagination_schema) do
      {:ok, validated_options} ->
        {:ok, validated_options}

      {:error, validation_error} ->
        validation_message = Exception.message(validation_error)

        {:error, ExQuickbooks.Error.validation_failed(validation_message)}
    end
  end
end
