defmodule ExQuickbooks.Response do
  @moduledoc """
  Shared response handling for QuickBooks resource requests.
  """

  @type result :: {:ok, term()} | {:error, ExQuickbooks.Error.t()}

  @doc """
  Parses a QuickBooks response into a success tuple or typed error.
  """
  @spec handle(Req.Response.t(), ExQuickbooks.Request.t()) :: result()
  def handle(response, request) do
    normalized_response_body = normalize_response_body(response.body)

    cond do
      success_status?(response.status) and fault_response?(normalized_response_body) ->
        {:error, fault_error(response, normalized_response_body)}

      success_status?(response.status) ->
        extract_success(response, request.response_path, normalized_response_body)

      true ->
        {:error, fault_error(response, normalized_response_body)}
    end
  end

  @doc """
  Returns the parsed `Retry-After` header value in seconds when present.
  """
  @spec retry_after_seconds(Req.Response.t()) :: non_neg_integer() | nil
  def retry_after_seconds(response) do
    response.headers
    |> retry_after_header()
    |> parse_retry_after()
  end

  defp extract_success(response, nil, _normalized_response_body) do
    {:ok, response.body}
  end

  defp extract_success(response, response_path, normalized_response_body) do
    case fetch_response_value(normalized_response_body, response_path) do
      {:ok, extracted_response_body} ->
        {:ok, ExQuickbooks.Payload.normalize_response(response_path, extracted_response_body)}

      :error ->
        {:error,
         ExQuickbooks.Error.new(:api_error,
           message: "QuickBooks response was missing #{Enum.join(response_path, ".")}",
           details: normalized_response_body,
           status: response.status
         )}
    end
  end

  defp fetch_response_value(response_body, response_path) do
    Enum.reduce_while(response_path, {:ok, response_body}, fn response_key,
                                                              {:ok, current_value} ->
      case fetch_response_key(current_value, response_key) do
        {:ok, next_value} ->
          {:cont, {:ok, next_value}}

        :error ->
          {:halt, :error}
      end
    end)
  end

  defp fetch_response_key(%{} = current_value, response_key) do
    Map.fetch(current_value, response_key)
  end

  defp fetch_response_key(_current_value, _response_key), do: :error

  defp fault_error(response, normalized_response_body) do
    fault = Map.get(normalized_response_body, "Fault", %{})
    fault_errors = fault_errors(fault)
    first_fault_error = List.first(fault_errors) || %{}
    error_type = error_type(response.status, fault)
    error_message = fault_error_message(first_fault_error)
    error_details = fault_details(normalized_response_body, response)

    ExQuickbooks.Error.new(error_type,
      message: error_message,
      details: error_details,
      status: response.status
    )
  end

  defp fault_error_message(first_fault_error) do
    Map.get(first_fault_error, "Detail") ||
      Map.get(first_fault_error, "Message") ||
      "QuickBooks request failed"
  end

  defp fault_details(normalized_response_body, response) do
    case retry_after_seconds(response) do
      nil -> normalized_response_body
      retry_after_seconds -> Map.put(normalized_response_body, "retry_after", retry_after_seconds)
    end
  end

  defp fault_errors(fault) do
    case Map.get(fault, "Error") do
      fault_errors when is_list(fault_errors) -> fault_errors
      %{} = fault_error -> [fault_error]
      _unexpected_fault_errors -> []
    end
  end

  defp error_type(status, fault)

  defp error_type(400, fault) do
    case Map.get(fault, "type") do
      "ValidationFault" -> :validation_failed
      _fault_type -> :api_error
    end
  end

  defp error_type(401, _fault), do: :unauthorized
  defp error_type(403, _fault), do: :forbidden
  defp error_type(404, _fault), do: :not_found
  defp error_type(429, _fault), do: :rate_limited
  defp error_type(status, _fault) when status >= 500, do: :server_error
  defp error_type(_status, _fault), do: :api_error

  defp retry_after_header(headers) do
    Enum.find_value(headers, fn {header_name, header_value} ->
      if String.downcase(header_name) == "retry-after" do
        header_value
      end
    end)
  end

  defp parse_retry_after(nil), do: nil

  defp parse_retry_after([retry_after_value | _remaining_values]),
    do: parse_retry_after(retry_after_value)

  defp parse_retry_after(retry_after_value) do
    case Integer.parse(retry_after_value) do
      {retry_after_seconds, ""} when retry_after_seconds >= 0 -> retry_after_seconds
      _parse_error -> nil
    end
  end

  defp normalize_response_body(%{} = response_body), do: response_body
  defp normalize_response_body(nil), do: %{}
  defp normalize_response_body(response_body), do: %{"raw_body" => response_body}

  defp fault_response?(normalized_response_body) do
    Map.has_key?(normalized_response_body, "Fault")
  end

  defp success_status?(status), do: status in 200..299
end
