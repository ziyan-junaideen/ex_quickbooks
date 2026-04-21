defmodule ExQuickbooks.Invoice do
  @moduledoc """
  Normalized QuickBooks invoice payload.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          sync_token: String.t() | nil,
          doc_number: String.t() | nil,
          total_amt: number() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :sync_token, :doc_number, :total_amt]

  @doc """
  Builds an invoice struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      sync_token: "SyncToken",
      doc_number: "DocNumber",
      total_amt: "TotalAmt"
    )
  end
end
