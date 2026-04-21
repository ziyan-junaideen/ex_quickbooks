defmodule ExQuickbooks.CompanyInfo do
  @moduledoc """
  Read-only access to the QuickBooks company information endpoint.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          company_name: String.t() | nil,
          legal_name: String.t() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :company_name, :legal_name]

  @doc """
  Builds a company info struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      company_name: "CompanyName",
      legal_name: "LegalName"
    )
  end

  @doc """
  Fetches the company information for the configured realm.
  """
  @spec get(ExQuickbooks.Client.t(), keyword()) ::
          {:ok, t()} | {:error, ExQuickbooks.Error.t()}
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
