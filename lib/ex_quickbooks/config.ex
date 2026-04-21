defmodule ExQuickbooks.Config do
  @moduledoc """
  Shared QuickBooks configuration helpers.
  """

  @sandbox_api_base_url "https://sandbox-quickbooks.api.intuit.com"
  @production_api_base_url "https://quickbooks.api.intuit.com"
  @oauth_authorization_endpoint "https://appcenter.intuit.com/connect/oauth2"
  @oauth_token_endpoint "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
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
  Returns the OAuth authorization endpoint.
  """
  @spec oauth_authorization_endpoint() :: String.t()
  def oauth_authorization_endpoint do
    @oauth_authorization_endpoint
  end

  @doc """
  Returns the OAuth token endpoint.
  """
  @spec oauth_token_endpoint() :: String.t()
  def oauth_token_endpoint do
    @oauth_token_endpoint
  end

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
