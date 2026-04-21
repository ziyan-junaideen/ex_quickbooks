defmodule ExQuickbooks.Request do
  @moduledoc """
  Shared path and query helpers for QuickBooks requests.
  """

  @type path_segment :: String.t() | atom() | integer()

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
