defmodule ExQuickbooks.Client do
  @moduledoc """
  Validated client configuration shared across ExQuickbooks modules.
  """

  @type environment :: :sandbox | :production

  @type t :: %__MODULE__{
          client_id: String.t(),
          client_secret: String.t(),
          redirect_uri: String.t(),
          realm_id: String.t(),
          access_token: String.t() | nil,
          refresh_token: String.t() | nil,
          environment: environment(),
          minor_version: pos_integer() | nil
        }

  @environments [:sandbox, :production]

  @schema [
    client_id: [type: :string, required: true],
    client_secret: [type: :string, required: true],
    redirect_uri: [type: :string, required: true],
    realm_id: [type: :string, required: true],
    access_token: [type: :string],
    refresh_token: [type: :string],
    environment: [type: {:in, @environments}, default: :sandbox],
    minor_version: [type: :pos_integer]
  ]

  @enforce_keys [:client_id, :client_secret, :redirect_uri, :realm_id, :environment]
  defstruct [
    :client_id,
    :client_secret,
    :redirect_uri,
    :realm_id,
    :access_token,
    :refresh_token,
    :environment,
    :minor_version
  ]

  @doc """
  Returns the supported QuickBooks environments.
  """
  @spec environments() :: [environment()]
  def environments do
    @environments
  end

  @doc """
  Returns the NimbleOptions schema for client validation.
  """
  @spec schema() :: keyword()
  def schema do
    @schema
  end

  @doc """
  Validates client options and returns a configured client struct.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, ExQuickbooks.Error.t()}
  def new(options) when is_list(options) do
    case NimbleOptions.validate(options, @schema) do
      {:ok, validated_options} ->
        client_attributes = Enum.into(validated_options, %{})

        {:ok, struct(__MODULE__, client_attributes)}

      {:error, validation_error} ->
        validation_message = Exception.message(validation_error)

        {:error, ExQuickbooks.Error.validation_failed(validation_message)}
    end
  end
end
