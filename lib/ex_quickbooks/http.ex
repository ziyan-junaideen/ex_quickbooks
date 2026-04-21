defmodule ExQuickbooks.HTTP do
  @moduledoc """
  Shared Req-based transport for QuickBooks company-scoped requests.
  """

  @retryable_statuses [429, 500, 502, 503, 504]
  @default_max_retries 2
  @default_retry_delay_ms 200

  @type request_option ::
          {:max_retries, non_neg_integer()}
          | {:sleep_function, (non_neg_integer() -> term())}
          | {:base_url, String.t()}

  @doc """
  Executes a shared QuickBooks request.
  """
  @spec request(ExQuickbooks.Client.t(), ExQuickbooks.Request.t(), [request_option()]) ::
          {:ok, term()} | {:error, ExQuickbooks.Error.t()}
  def request(client, request, options \\ []) do
    max_retries = Keyword.get(options, :max_retries, @default_max_retries)
    sleep_function = Keyword.get(options, :sleep_function, &Process.sleep/1)
    base_url = Keyword.get(options, :base_url, ExQuickbooks.Config.api_base_url(client))

    perform_request(client, request, base_url, 0, max_retries, sleep_function)
  end

  defp perform_request(client, request, base_url, attempt_count, max_retries, sleep_function) do
    request_options = build_request_options(client, request, base_url)

    case Req.request(request_options) do
      {:ok, response} ->
        maybe_retry(
          client,
          request,
          base_url,
          response,
          attempt_count,
          max_retries,
          sleep_function
        )

      {:error, request_error} ->
        {:error,
         ExQuickbooks.Error.new(:network_error,
           message: Exception.message(request_error),
           details: %{reason: inspect(request_error)}
         )}
    end
  end

  defp maybe_retry(
         client,
         request,
         base_url,
         response,
         attempt_count,
         max_retries,
         sleep_function
       ) do
    if attempt_count < max_retries and retryable_response?(response) do
      retry_delay_ms = retry_delay_ms(response, attempt_count)
      sleep_function.(retry_delay_ms)

      perform_request(client, request, base_url, attempt_count + 1, max_retries, sleep_function)
    else
      ExQuickbooks.Response.handle(response, request)
    end
  end

  defp build_request_options(client, request, base_url) do
    base_request_options = [
      method: request.method,
      url: base_url <> ExQuickbooks.Request.company_url_path(client, request),
      headers: merge_headers(ExQuickbooks.Config.request_headers(client), request.headers),
      retry: false
    ]

    put_request_body(base_request_options, request)
  end

  defp put_request_body(request_options, %ExQuickbooks.Request{body: nil}), do: request_options

  defp put_request_body(request_options, %ExQuickbooks.Request{body_format: :json, body: body}) do
    Keyword.put(request_options, :json, body)
  end

  defp put_request_body(request_options, %ExQuickbooks.Request{body_format: :text, body: body}) do
    Keyword.put(request_options, :body, body)
  end

  defp merge_headers(base_headers, override_headers) do
    base_header_map = header_map(base_headers)
    override_header_map = header_map(override_headers)

    base_header_map
    |> Map.merge(override_header_map)
    |> Enum.to_list()
  end

  defp header_map(headers) do
    Enum.into(headers, %{}, fn {header_name, header_value} ->
      {String.downcase(header_name), header_value}
    end)
  end

  defp retryable_response?(response) do
    response.status in @retryable_statuses
  end

  defp retry_delay_ms(response, attempt_count) do
    case ExQuickbooks.Response.retry_after_seconds(response) do
      retry_after_seconds when is_integer(retry_after_seconds) ->
        retry_after_seconds * 1000

      nil ->
        exponential_backoff_ms(attempt_count)
    end
  end

  defp exponential_backoff_ms(attempt_count) do
    trunc(:math.pow(2, attempt_count) * @default_retry_delay_ms)
  end
end
