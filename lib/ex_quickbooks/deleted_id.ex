defmodule ExQuickbooks.DeletedId do
  @moduledoc """
  Normalized QuickBooks CDC deleted-id payload.

  The original QuickBooks response body remains available in `attributes`.
  """

  @type t :: %__MODULE__{
          attributes: map(),
          id: String.t() | nil,
          type: String.t() | nil
        }

  @enforce_keys [:attributes]
  defstruct [:attributes, :id, :type]

  @doc """
  Builds a deleted-id struct from a QuickBooks payload map.
  """
  @spec new(map()) :: t()
  def new(attributes) when is_map(attributes) do
    ExQuickbooks.Entity.build(__MODULE__, attributes,
      id: "Id",
      type: "Type"
    )
  end
end
