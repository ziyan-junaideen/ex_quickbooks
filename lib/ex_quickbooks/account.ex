defmodule ExQuickbooks.Account do
  @moduledoc """
  Normalized QuickBooks account payload.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          sync_token: String.t() | nil,
          name: String.t() | nil,
          active: boolean() | nil,
          account_type: String.t() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :sync_token, :name, :active, :account_type]

  @doc """
  Builds an account struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      sync_token: "SyncToken",
      name: "Name",
      active: "Active",
      account_type: "AccountType"
    )
  end
end
