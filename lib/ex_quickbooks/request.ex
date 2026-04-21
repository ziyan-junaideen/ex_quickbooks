defmodule ExQuickbooks.Request do
  @moduledoc """
  Shared request builders for QuickBooks company-scoped endpoints.

  Request helpers return a struct that the shared HTTP pipeline can execute with
  `ExQuickbooks.request/2`.
  """

  @type path_segment :: String.t() | atom() | integer()
  @type method :: :get | :post
  @type body_format :: :json | :text
  @type response_path :: [String.t()] | nil

  @type t :: %__MODULE__{
          method: method(),
          path_segments: [path_segment()],
          query: keyword(),
          headers: [{String.t(), String.t()}],
          body: map() | String.t() | nil,
          body_format: body_format(),
          response_path: response_path()
        }

  defstruct method: :get,
            path_segments: [],
            query: [],
            headers: [],
            body: nil,
            body_format: :json,
            response_path: nil

  @doc """
  Builds a GET request for a company-scoped entity endpoint.
  """
  @spec get([path_segment()] | path_segment(), keyword()) :: t()
  def get(path_segments, options \\ []) do
    build_request(
      method: :get,
      path_segments: path_segments,
      query: Keyword.get(options, :query, []),
      headers: Keyword.get(options, :headers, []),
      response_path: Keyword.get(options, :response_path)
    )
  end

  @doc """
  Builds a POST create request for a company-scoped entity endpoint.
  """
  @spec create([path_segment()] | path_segment(), map(), keyword()) :: t()
  def create(path_segments, body, options \\ []) when is_map(body) do
    build_request(
      method: :post,
      path_segments: path_segments,
      query: Keyword.get(options, :query, []),
      headers: Keyword.get(options, :headers, []),
      body: body,
      body_format: :json,
      response_path: Keyword.get(options, :response_path)
    )
  end

  @doc """
  Builds a POST update request with `operation=update`.
  """
  @spec update([path_segment()] | path_segment(), map(), keyword()) :: t()
  def update(path_segments, body, options \\ []) when is_map(body) do
    query_parameters =
      options
      |> Keyword.get(:query, [])
      |> normalize_query_parameters()
      |> Keyword.put(:operation, "update")

    build_request(
      method: :post,
      path_segments: path_segments,
      query: query_parameters,
      headers: Keyword.get(options, :headers, []),
      body: body,
      body_format: :json,
      response_path: Keyword.get(options, :response_path)
    )
  end

  @doc """
  Builds a POST operation request, such as `void` or `delete`.
  """
  @spec operation([path_segment()] | path_segment(), String.t() | atom(), map(), keyword()) :: t()
  def operation(path_segments, operation_name, body, options \\ []) when is_map(body) do
    query_parameters =
      options
      |> Keyword.get(:query, [])
      |> normalize_query_parameters()
      |> Keyword.put(:operation, to_string(operation_name))

    build_request(
      method: :post,
      path_segments: path_segments,
      query: query_parameters,
      headers: Keyword.get(options, :headers, []),
      body: body,
      body_format: :json,
      response_path: Keyword.get(options, :response_path)
    )
  end

  @doc """
  Builds a POST query request with a plain-text QuickBooks query statement.
  """
  @spec query(String.t(), keyword()) :: t()
  def query(statement, options \\ []) when is_binary(statement) do
    build_request(
      method: :post,
      path_segments: ["query"],
      query: Keyword.get(options, :query, []),
      headers: [{"content-type", "text/plain"} | Keyword.get(options, :headers, [])],
      body: statement,
      body_format: :text,
      response_path: Keyword.get(options, :response_path, ["QueryResponse"])
    )
  end

  @doc """
  Builds a POST CDC request.
  """
  @spec cdc([String.t() | atom()] | String.t(), DateTime.t() | String.t(), keyword()) :: t()
  def cdc(entity_names, changed_since, options \\ []) do
    body = %{
      "entities" => normalize_entity_names(entity_names),
      "changedSince" => normalize_changed_since(changed_since)
    }

    build_request(
      method: :post,
      path_segments: ["cdc"],
      query: Keyword.get(options, :query, []),
      headers: Keyword.get(options, :headers, []),
      body: body,
      body_format: :json,
      response_path: Keyword.get(options, :response_path, ["CDCResponse"])
    )
  end

  @doc """
  Builds the company-scoped URL path for a request struct.
  """
  @spec company_url_path(ExQuickbooks.Client.t(), t()) :: String.t()
  def company_url_path(client, request) do
    company_path(client, request.path_segments, query: request.query)
  end

  @doc """
  Builds a `/v3/company/:realm_id/...` path and appends query parameters.
  """
  @spec company_path(ExQuickbooks.Client.t(), [path_segment()] | path_segment(), keyword()) ::
          String.t()
  def company_path(client, path_segments, options \\ []) do
    normalized_path_segments = normalize_path_segments(path_segments)

    path =
      ["v3", "company", client.realm_id | normalized_path_segments]
      |> Enum.map_join("/", &normalize_path_segment/1)
      |> then(&("/" <> &1))

    query_parameters =
      options
      |> Keyword.get(:query, [])
      |> normalize_query_parameters()
      |> put_minor_version(client.minor_version)

    append_query(path, query_parameters)
  end

  defp build_request(options) do
    %__MODULE__{
      method: Keyword.fetch!(options, :method),
      path_segments: normalize_path_segments(Keyword.fetch!(options, :path_segments)),
      query: normalize_query_parameters(Keyword.get(options, :query, [])),
      headers: Keyword.get(options, :headers, []),
      body: Keyword.get(options, :body),
      body_format: Keyword.get(options, :body_format, :json),
      response_path: normalize_response_path(Keyword.get(options, :response_path))
    }
  end

  defp normalize_entity_names(entity_names) when is_binary(entity_names), do: entity_names

  defp normalize_entity_names(entity_names) when is_list(entity_names) do
    Enum.map_join(entity_names, ",", &to_string/1)
  end

  defp normalize_changed_since(%DateTime{} = changed_since),
    do: DateTime.to_iso8601(changed_since)

  defp normalize_changed_since(changed_since) when is_binary(changed_since), do: changed_since

  defp normalize_response_path(nil), do: nil
  defp normalize_response_path(response_path) when is_binary(response_path), do: [response_path]

  defp normalize_response_path(response_path) when is_list(response_path) do
    Enum.map(response_path, &to_string/1)
  end

  defp normalize_path_segments(path_segments) when is_list(path_segments), do: path_segments
  defp normalize_path_segments(path_segments), do: [path_segments]

  defp normalize_path_segment(path_segment) do
    path_segment
    |> to_string()
    |> URI.encode_www_form()
  end

  defp normalize_query_parameters(query_parameters) when is_list(query_parameters),
    do: query_parameters

  defp normalize_query_parameters(query_parameters) when is_map(query_parameters),
    do: Map.to_list(query_parameters)

  defp put_minor_version(query_parameters, nil), do: query_parameters

  defp put_minor_version(query_parameters, minor_version) do
    if Enum.any?(query_parameters, &minor_version_parameter?/1) do
      query_parameters
    else
      query_parameters ++ [minorversion: minor_version]
    end
  end

  defp minor_version_parameter?({parameter_name, _parameter_value}) do
    parameter_name in [:minorversion, "minorversion"]
  end

  defp append_query(path, []), do: path
  defp append_query(path, query_parameters), do: path <> "?" <> URI.encode_query(query_parameters)
end
