defmodule ExQuickbooks.Item do
  @moduledoc """
  Normalized QuickBooks item payload.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          sync_token: String.t() | nil,
          name: String.t() | nil,
          active: boolean() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :sync_token, :name, :active]

  @doc """
  Builds an item struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      sync_token: "SyncToken",
      name: "Name",
      active: "Active"
    )
  end
end
