defmodule ExQuickbooks do
  @moduledoc """
  Public entry points for configuring ExQuickbooks.

  ExQuickbooks is a small Elixir client for the QuickBooks Online Accounting
  API. It focuses on a clear library surface: create a validated client, run
  OAuth flows, execute shared requests, and work with decoded QuickBooks maps.

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

  ## Examples

      iex> {:ok, client} =
      ...>   ExQuickbooks.new(
      ...>     client_id: "client-id",
      ...>     client_secret: "client-secret",
      ...>     redirect_uri: "https://example.com/callback",
      ...>     realm_id: "9130357992221046",
      ...>     minor_version: 75
      ...>   )
      iex> ExQuickbooks.request_path(client, ["customer"], query: [active: true])
      "/v3/company/9130357992221046/customer?active=true&minorversion=75"
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
