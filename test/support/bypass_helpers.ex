defmodule ExQuickbooks.TestSupport.BypassHelpers do
  @moduledoc false

  import ExUnit.Assertions

  @spec assert_request(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def assert_request(connection, options) do
    expected_method = options[:method]
    expected_url = options[:url]
    expected_headers = Keyword.get(options, :headers, [])
    expected_body = Keyword.get(options, :body, :any)

    if expected_method do
      assert connection.method == normalize_method(expected_method)
    end

    if expected_url do
      assert request_url(connection) == expected_url
    end

    assert_headers(connection, expected_headers)
    assert_body(connection, expected_body)
  end

  defp request_url(connection) do
    case connection.query_string do
      "" -> connection.request_path
      query_string -> connection.request_path <> "?" <> query_string
    end
  end

  defp assert_headers(connection, expected_headers) do
    request_headers =
      Enum.into(connection.req_headers, %{}, fn {header_name, header_value} ->
        {String.downcase(header_name), header_value}
      end)

    Enum.each(expected_headers, fn {header_name, header_value} ->
      assert Map.get(request_headers, String.downcase(header_name)) == header_value
    end)
  end

  defp assert_body(connection, :any), do: connection

  defp assert_body(connection, expected_body) do
    {:ok, request_body, connection} = Plug.Conn.read_body(connection)

    case expected_body do
      nil ->
        assert request_body == ""

      expected_body when is_binary(expected_body) ->
        assert request_body == expected_body

      expected_body ->
        assert Jason.decode!(request_body) == expected_body
    end

    connection
  end

  defp normalize_method(method) do
    method
    |> to_string()
    |> String.upcase()
  end
end
