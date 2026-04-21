defmodule ExQuickbooks do
  @moduledoc """
  Public entry points for configuring ExQuickbooks.

  The library currently provides:

  - a validated client struct for QuickBooks API configuration
  - shared request builders and an HTTP pipeline for company-scoped endpoints
  - read-only bootstrap modules for company info and generic queries
  - resource modules for customers, items, invoices, payments, accounts, and vendors
  - CDC helpers for grouped incremental sync results
  - OAuth 2 helpers for authorization URL generation, code exchange, and token refresh

  ## Examples

      iex> {:ok, %ExQuickbooks.Client{environment: :sandbox}} =
      ...>   ExQuickbooks.new(
      ...>     client_id: "client-id",
      ...>     client_secret: "client-secret",
      ...>     redirect_uri: "https://example.com/callback",
      ...>     realm_id: "9130357992221046"
      ...>   )
  """

  @doc """
  Builds a validated client for later QuickBooks requests.
  """
  @spec new(keyword()) :: {:ok, ExQuickbooks.Client.t()} | {:error, ExQuickbooks.Error.t()}
  def new(options) when is_list(options) do
    ExQuickbooks.Client.new(options)
  end

  @doc """
  Builds a shared `/v3/company/:realm_id/...` request path.
  """
  @spec request_path(ExQuickbooks.Client.t(), [String.t() | atom() | integer()], keyword()) ::
          String.t()
  def request_path(client, path_segments, options \\ []) do
    ExQuickbooks.Request.company_path(client, path_segments, options)
  end

  @doc """
  Executes a shared QuickBooks request.
  """
  @spec request(ExQuickbooks.Client.t(), ExQuickbooks.Request.t(), keyword()) ::
          {:ok, term()} | {:error, ExQuickbooks.Error.t()}
  def request(client, request, options \\ []) do
    ExQuickbooks.HTTP.request(client, request, options)
  end
end
