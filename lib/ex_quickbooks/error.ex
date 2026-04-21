defmodule ExQuickbooks.Error do
  @moduledoc """
  Typed error values returned by ExQuickbooks for expected failures.
  """

  @type type ::
          :unauthorized
          | :forbidden
          | :not_found
          | :rate_limited
          | :validation_failed
          | :api_error
          | :network_error
          | :server_error

  @type t :: %__MODULE__{
          type: type(),
          message: String.t() | nil,
          details: map() | nil,
          status: pos_integer() | nil
        }

  @allowed_types [
    :unauthorized,
    :forbidden,
    :not_found,
    :rate_limited,
    :validation_failed,
    :api_error,
    :network_error,
    :server_error
  ]

  @enforce_keys [:type]
  defstruct [:type, :message, :details, :status]

  @doc """
  Builds a typed error value.
  """
  @spec new(type(), keyword()) :: t()
  def new(type, options \\ []) when type in @allowed_types and is_list(options) do
    %__MODULE__{
      type: type,
      message: Keyword.get(options, :message),
      details: Keyword.get(options, :details),
      status: Keyword.get(options, :status)
    }
  end

  @doc """
  Builds a validation error value.
  """
  @spec validation_failed(String.t(), map() | nil) :: t()
  def validation_failed(message, details \\ nil) do
    new(:validation_failed, message: message, details: details)
  end
end
