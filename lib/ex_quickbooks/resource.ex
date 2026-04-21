defmodule ExQuickbooks.Resource do
  @moduledoc false

  @list_options_schema [
    where: [type: :string]
  ]

  @spec list(ExQuickbooks.Client.t(), String.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickbooks.Error.t()}
  def list(client, resource_name, options \\ []) do
    list_specific_options = Keyword.take(options, [:where])

    with {:ok, validated_list_options} <- validate_list_options(list_specific_options),
         {:ok, query_response} <-
           ExQuickbooks.Query.run(
             client,
             list_statement(resource_name, validated_list_options),
             query_options(options)
           ) do
      {:ok, Map.get(query_response, resource_name, [])}
    end
  end

  @spec get(ExQuickbooks.Client.t(), String.t(), String.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickbooks.Error.t()}
  def get(client, resource_path, resource_name, id, options \\ []) do
    request =
      ExQuickbooks.Request.get(
        [resource_path, id],
        response_path: [resource_name]
      )

    ExQuickbooks.request(client, request, request_options(options))
  end

  @spec create(ExQuickbooks.Client.t(), String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickbooks.Error.t()}
  def create(client, resource_path, resource_name, attributes, options \\ []) do
    request =
      ExQuickbooks.Request.create(
        [resource_path],
        attributes,
        response_path: [resource_name]
      )

    ExQuickbooks.request(client, request, request_options(options))
  end

  @spec update(ExQuickbooks.Client.t(), String.t(), String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickbooks.Error.t()}
  def update(client, resource_path, resource_name, attributes, options \\ []) do
    request =
      ExQuickbooks.Request.update(
        [resource_path],
        attributes,
        response_path: [resource_name]
      )

    ExQuickbooks.request(client, request, request_options(options))
  end

  defp list_statement(resource_name, validated_list_options) do
    statement = "SELECT * FROM " <> resource_name

    case validated_list_options[:where] do
      nil -> statement
      where_clause -> statement <> " WHERE " <> where_clause
    end
  end

  defp query_options(options) do
    query_options =
      Keyword.take(options, [
        :where,
        :start_position,
        :max_results,
        :base_url,
        :max_retries,
        :sleep_function
      ])

    Keyword.delete(query_options, :where)
  end

  defp request_options(options) do
    Keyword.take(options, [:base_url, :max_retries, :sleep_function])
  end

  defp validate_list_options(options) do
    case NimbleOptions.validate(options, @list_options_schema) do
      {:ok, validated_options} ->
        {:ok, validated_options}

      {:error, validation_error} ->
        validation_message = Exception.message(validation_error)

        {:error, ExQuickbooks.Error.validation_failed(validation_message)}
    end
  end
end
