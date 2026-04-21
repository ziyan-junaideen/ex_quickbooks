defmodule ExQuickbooks.Config do
  @moduledoc """
  Shared QuickBooks configuration helpers.
  """

  @sandbox_api_base_url "https://sandbox-quickbooks.api.intuit.com"
  @production_api_base_url "https://quickbooks.api.intuit.com"
  @json_headers [{"accept", "application/json"}, {"content-type", "application/json"}]

  @doc """
  Returns the API base URL for a configured client or environment.
  """
  @spec api_base_url(ExQuickbooks.Client.t() | ExQuickbooks.Client.environment()) :: String.t()
  def api_base_url(%ExQuickbooks.Client{environment: environment}) do
    api_base_url(environment)
  end

  def api_base_url(:sandbox), do: @sandbox_api_base_url
  def api_base_url(:production), do: @production_api_base_url

  @doc """
  Returns default JSON headers and includes bearer auth when an access token exists.
  """
  @spec request_headers(ExQuickbooks.Client.t()) :: [{String.t(), String.t()}]
  def request_headers(client) do
    case client.access_token do
      nil -> @json_headers
      access_token -> [{"authorization", "Bearer " <> access_token} | @json_headers]
    end
  end
end
