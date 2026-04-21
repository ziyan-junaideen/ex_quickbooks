defmodule ExQuickbooks.Payment do
  @moduledoc """
  Normalized QuickBooks payment payload.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          sync_token: String.t() | nil,
          total_amt: number() | nil,
          private_note: String.t() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :sync_token, :total_amt, :private_note]

  @doc """
  Builds a payment struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      sync_token: "SyncToken",
      total_amt: "TotalAmt",
      private_note: "PrivateNote"
    )
  end
end
