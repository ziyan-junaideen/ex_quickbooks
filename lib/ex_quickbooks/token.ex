defmodule ExQuickbooks.Token do
  @moduledoc """
  OAuth token data returned by QuickBooks.

  The struct preserves the access token, refresh token, their expiry metadata,
  and the realm ID when the caller has it from the OAuth callback.
  """

  @type t :: %__MODULE__{
          access_token: String.t(),
          refresh_token: String.t(),
          token_type: String.t(),
          expires_in: pos_integer(),
          refresh_token_expires_in: pos_integer(),
          access_token_expires_at: DateTime.t(),
          refresh_token_expires_at: DateTime.t(),
          realm_id: String.t() | nil
        }

  @enforce_keys [
    :access_token,
    :refresh_token,
    :token_type,
    :expires_in,
    :refresh_token_expires_in,
    :access_token_expires_at,
    :refresh_token_expires_at
  ]
  defstruct [
    :access_token,
    :refresh_token,
    :token_type,
    :expires_in,
    :refresh_token_expires_in,
    :access_token_expires_at,
    :refresh_token_expires_at,
    :realm_id
  ]

  @doc """
  Builds a token struct from the QuickBooks OAuth response body.
  """
  @spec from_oauth_response(map(), keyword()) :: {:ok, t()} | {:error, ExQuickbooks.Error.t()}
  def from_oauth_response(response_body, options \\ []) when is_map(response_body) do
    current_time = Keyword.get(options, :current_time, DateTime.utc_now())
    realm_id = Keyword.get(options, :realm_id)

    case fetch_token_attributes(response_body) do
      {:ok, token_attributes} ->
        {:ok, build_token(token_attributes, current_time, realm_id)}

      {:error, missing_field_name} ->
        {:error,
         ExQuickbooks.Error.new(:api_error,
           message: "OAuth token response was missing #{missing_field_name}",
           details: response_body
         )}
    end
  end

  @doc """
  Returns true when the access token has expired at or before the given time.
  """
  @spec access_token_expired?(t(), DateTime.t()) :: boolean()
  def access_token_expired?(token, current_time \\ DateTime.utc_now()) do
    DateTime.compare(token.access_token_expires_at, current_time) != :gt
  end

  @doc """
  Returns true when the refresh token has expired at or before the given time.
  """
  @spec refresh_token_expired?(t(), DateTime.t()) :: boolean()
  def refresh_token_expired?(token, current_time \\ DateTime.utc_now()) do
    DateTime.compare(token.refresh_token_expires_at, current_time) != :gt
  end

  defp fetch_string(response_body, key) do
    case Map.fetch(response_body, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      _missing_value -> {:error, key}
    end
  end

  defp fetch_token_attributes(response_body) do
    with {:ok, access_token} <- fetch_string(response_body, "access_token"),
         {:ok, refresh_token} <- fetch_string(response_body, "refresh_token"),
         {:ok, token_type} <- fetch_string(response_body, "token_type"),
         {:ok, expires_in} <- fetch_integer(response_body, "expires_in"),
         {:ok, refresh_token_expires_in} <-
           fetch_integer(response_body, "x_refresh_token_expires_in") do
      {:ok,
       %{
         access_token: access_token,
         refresh_token: refresh_token,
         token_type: token_type,
         expires_in: expires_in,
         refresh_token_expires_in: refresh_token_expires_in
       }}
    end
  end

  defp fetch_integer(response_body, key) do
    case Map.fetch(response_body, key) do
      {:ok, value} when is_integer(value) and value > 0 ->
        {:ok, value}

      {:ok, value} when is_binary(value) ->
        parse_integer(value, key)

      _missing_value ->
        {:error, key}
    end
  end

  defp parse_integer(value, key) do
    case Integer.parse(value) do
      {parsed_value, ""} when parsed_value > 0 -> {:ok, parsed_value}
      _parse_error -> {:error, key}
    end
  end

  defp build_token(token_attributes, current_time, realm_id) do
    %__MODULE__{
      access_token: token_attributes.access_token,
      refresh_token: token_attributes.refresh_token,
      token_type: token_attributes.token_type,
      expires_in: token_attributes.expires_in,
      refresh_token_expires_in: token_attributes.refresh_token_expires_in,
      access_token_expires_at: DateTime.add(current_time, token_attributes.expires_in, :second),
      refresh_token_expires_at:
        DateTime.add(current_time, token_attributes.refresh_token_expires_in, :second),
      realm_id: realm_id
    }
  end
end
