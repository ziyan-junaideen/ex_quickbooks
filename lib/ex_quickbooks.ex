defmodule ExQuickbooks do
  @moduledoc """
  Public entry points for configuring ExQuickbooks.

  Phase 1 provides a validated client struct plus shared request path helpers
  that the later auth and resource modules can build on.

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
end
