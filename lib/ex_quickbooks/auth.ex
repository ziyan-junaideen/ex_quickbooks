defmodule ExQuickbooks.Auth do
  @moduledoc """
  OAuth 2 helpers for QuickBooks Online.

  These helpers generate the authorization URL, exchange an authorization code
  for tokens, and refresh rotated token credentials without persisting them.
  """

  @default_scopes ["com.intuit.quickbooks.accounting"]

  @authorization_url_schema [
    client_id: [type: :string, required: true],
    redirect_uri: [type: :string, required: true],
    scopes: [type: {:list, :string}, default: @default_scopes],
    state: [type: :string]
  ]

  @exchange_code_schema [
    client_id: [type: :string, required: true],
    client_secret: [type: :string, required: true],
    redirect_uri: [type: :string, required: true],
    code: [type: :string, required: true],
    realm_id: [type: :string],
    token_endpoint: [type: :string, default: ExQuickbooks.Config.oauth_token_endpoint()]
  ]

  @refresh_tokens_schema [
    client_id: [type: :string, required: true],
    client_secret: [type: :string, required: true],
    refresh_token: [type: :string, required: true],
    realm_id: [type: :string],
    token_endpoint: [type: :string, default: ExQuickbooks.Config.oauth_token_endpoint()]
  ]

  @doc """
  Builds the QuickBooks authorization URL.
  """
  @spec authorization_url(keyword()) :: {:ok, String.t()} | {:error, ExQuickbooks.Error.t()}
  def authorization_url(options) when is_list(options) do
    with {:ok, validated_options} <- validate_options(options, @authorization_url_schema) do
      query_parameters = authorization_query_parameters(validated_options)

      {:ok,
       ExQuickbooks.Config.oauth_authorization_endpoint() <>
         "?" <> URI.encode_query(query_parameters)}
    end
  end

  @doc """
  Exchanges an authorization code for QuickBooks OAuth tokens.
  """
  @spec exchange_code(keyword()) ::
          {:ok, ExQuickbooks.Token.t()} | {:error, ExQuickbooks.Error.t()}
  def exchange_code(options) when is_list(options) do
    with {:ok, validated_options} <- validate_options(options, @exchange_code_schema) do
      request_form =
        [
          grant_type: "authorization_code",
          code: validated_options[:code],
          redirect_uri: validated_options[:redirect_uri]
        ]

      request_token(validated_options, request_form)
    end
  end

  @doc """
  Refreshes QuickBooks OAuth tokens using the latest refresh token.
  """
  @spec refresh_tokens(keyword()) ::
          {:ok, ExQuickbooks.Token.t()} | {:error, ExQuickbooks.Error.t()}
  def refresh_tokens(options) when is_list(options) do
    with {:ok, validated_options} <- validate_options(options, @refresh_tokens_schema) do
      request_form = [
        grant_type: "refresh_token",
        refresh_token: validated_options[:refresh_token]
      ]

      request_token(validated_options, request_form)
    end
  end

  defp request_token(validated_options, request_form) do
    authorization_header =
      basic_authorization_header(validated_options[:client_id], validated_options[:client_secret])

    case Req.post(validated_options[:token_endpoint],
           headers: [{"accept", "application/json"}, {"authorization", authorization_header}],
           form: request_form
         ) do
      {:ok, response} ->
        handle_token_response(response, validated_options)

      {:error, request_error} ->
        {:error,
         ExQuickbooks.Error.new(:network_error,
           message: Exception.message(request_error),
           details: %{reason: inspect(request_error)}
         )}
    end
  end

  defp handle_token_response(response, validated_options) do
    case response.status do
      status when status in 200..299 ->
        ExQuickbooks.Token.from_oauth_response(response.body,
          realm_id: validated_options[:realm_id]
        )

      _other_status ->
        {:error, auth_error(response)}
    end
  end

  defp auth_error(response) do
    response_body = normalize_response_body(response.body)
    oauth_error = Map.get(response_body, "error")
    oauth_error_description = Map.get(response_body, "error_description")
    error_type = error_type(response.status, oauth_error)
    error_message = oauth_error_description || oauth_error || "QuickBooks OAuth request failed"

    ExQuickbooks.Error.new(error_type,
      message: error_message,
      details: response_body,
      status: response.status
    )
  end

  defp error_type(status, oauth_error)

  defp error_type(400, "invalid_grant"), do: :unauthorized
  defp error_type(400, _oauth_error), do: :validation_failed
  defp error_type(401, _oauth_error), do: :unauthorized
  defp error_type(403, _oauth_error), do: :forbidden
  defp error_type(429, _oauth_error), do: :rate_limited
  defp error_type(status, _oauth_error) when status >= 500, do: :server_error
  defp error_type(_status, _oauth_error), do: :api_error

  defp normalize_response_body(response_body) when is_map(response_body), do: response_body
  defp normalize_response_body(_response_body), do: %{}

  defp basic_authorization_header(client_id, client_secret) do
    encoded_credentials = Base.encode64(client_id <> ":" <> client_secret)

    "Basic " <> encoded_credentials
  end

  defp authorization_query_parameters(validated_options) do
    query_parameters = [
      client_id: validated_options[:client_id],
      redirect_uri: validated_options[:redirect_uri],
      response_type: "code",
      scope: Enum.join(validated_options[:scopes], " ")
    ]

    maybe_put_state(query_parameters, validated_options[:state])
  end

  defp maybe_put_state(query_parameters, nil), do: query_parameters
  defp maybe_put_state(query_parameters, state), do: query_parameters ++ [state: state]

  defp validate_options(options, schema) do
    case NimbleOptions.validate(options, schema) do
      {:ok, validated_options} ->
        {:ok, validated_options}

      {:error, validation_error} ->
        validation_message = Exception.message(validation_error)

        {:error, ExQuickbooks.Error.validation_failed(validation_message)}
    end
  end
end
