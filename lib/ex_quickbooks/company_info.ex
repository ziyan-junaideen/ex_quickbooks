defmodule ExQuickbooks.CompanyInfo do
  @moduledoc """
  Read-only access to the QuickBooks company information endpoint.
  """

  @doc """
  Fetches the company information for the configured realm.
  """
  @spec get(ExQuickbooks.Client.t(), keyword()) ::
          {:ok, map()} | {:error, ExQuickbooks.Error.t()}
  def get(client, options \\ []) do
    company_info_request =
      ExQuickbooks.Request.get(
        ["companyinfo", client.realm_id],
        response_path: ["CompanyInfo"]
      )

    ExQuickbooks.request(client, company_info_request, request_options(options))
  end

  defp request_options(options) do
    Keyword.take(options, [:base_url, :max_retries, :sleep_function])
  end
end
