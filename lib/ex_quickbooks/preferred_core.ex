defmodule ExQuickBooks.Error do
  @moduledoc """
  Typed error values returned by the preferred `ExQuickBooks` API.
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

  @doc false
  @spec from_legacy(ExQuickbooks.Error.t()) :: t()
  def from_legacy(%ExQuickbooks.Error{} = error) do
    %__MODULE__{
      type: error.type,
      message: error.message,
      details: error.details,
      status: error.status
    }
  end

  @doc false
  @spec to_legacy(t()) :: ExQuickbooks.Error.t()
  def to_legacy(%__MODULE__{} = error) do
    %ExQuickbooks.Error{
      type: error.type,
      message: error.message,
      details: error.details,
      status: error.status
    }
  end
end

defmodule ExQuickBooks.Client do
  @moduledoc """
  Validated client configuration shared across `ExQuickBooks` modules.
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
    ExQuickbooks.Client.environments()
  end

  @doc """
  Returns the NimbleOptions schema for client validation.
  """
  @spec schema() :: keyword()
  def schema do
    ExQuickbooks.Client.schema()
  end

  @doc """
  Validates client options and returns a configured client struct.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, ExQuickBooks.Error.t()}
  def new(options) when is_list(options) do
    options
    |> ExQuickbooks.Client.new()
    |> ExQuickbooks.PreferredAPI.new_client_result()
  end

  @doc false
  @spec from_legacy(ExQuickbooks.Client.t()) :: t()
  def from_legacy(%ExQuickbooks.Client{} = client) do
    client
    |> Map.from_struct()
    |> then(&struct(__MODULE__, &1))
  end

  @doc false
  @spec to_legacy(t()) :: ExQuickbooks.Client.t()
  def to_legacy(%__MODULE__{} = client) do
    client
    |> Map.from_struct()
    |> then(&struct(ExQuickbooks.Client, &1))
  end
end

defmodule ExQuickBooks.Token do
  @moduledoc """
  OAuth token data returned by QuickBooks.
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
  @spec from_oauth_response(map(), keyword()) ::
          {:ok, t()} | {:error, ExQuickBooks.Error.t()}
  def from_oauth_response(response_body, options \\ []) when is_map(response_body) do
    response_body
    |> ExQuickbooks.Token.from_oauth_response(options)
    |> ExQuickbooks.PreferredAPI.new_token_result()
  end

  @doc """
  Returns true when the access token has expired at or before the given time.
  """
  @spec access_token_expired?(t(), DateTime.t()) :: boolean()
  def access_token_expired?(token, current_time \\ DateTime.utc_now()) do
    token
    |> to_legacy()
    |> ExQuickbooks.Token.access_token_expired?(current_time)
  end

  @doc """
  Returns true when the refresh token has expired at or before the given time.
  """
  @spec refresh_token_expired?(t(), DateTime.t()) :: boolean()
  def refresh_token_expired?(token, current_time \\ DateTime.utc_now()) do
    token
    |> to_legacy()
    |> ExQuickbooks.Token.refresh_token_expired?(current_time)
  end

  @doc false
  @spec from_legacy(ExQuickbooks.Token.t()) :: t()
  def from_legacy(%ExQuickbooks.Token{} = token) do
    token
    |> Map.from_struct()
    |> then(&struct(__MODULE__, &1))
  end

  @doc false
  @spec to_legacy(t()) :: ExQuickbooks.Token.t()
  def to_legacy(%__MODULE__{} = token) do
    token
    |> Map.from_struct()
    |> then(&struct(ExQuickbooks.Token, &1))
  end
end

defmodule ExQuickBooks.Request do
  @moduledoc """
  Shared request builders for QuickBooks company-scoped endpoints.

  Request helpers return a struct that the shared HTTP pipeline can execute with
  `ExQuickBooks.request/2`.
  """

  @type path_segment :: String.t() | atom() | integer()
  @type method :: :get | :post
  @type body_format :: :json | :text
  @type response_path :: [String.t()] | nil

  @type t :: %__MODULE__{
          method: method(),
          path_segments: [path_segment()],
          query: keyword(),
          headers: [{String.t(), String.t()}],
          body: map() | String.t() | nil,
          body_format: body_format(),
          response_path: response_path()
        }

  defstruct method: :get,
            path_segments: [],
            query: [],
            headers: [],
            body: nil,
            body_format: :json,
            response_path: nil

  @doc """
  Builds a GET request for a company-scoped entity endpoint.
  """
  @spec get([path_segment()] | path_segment(), keyword()) :: t()
  def get(path_segments, options \\ []) do
    path_segments
    |> ExQuickbooks.Request.get(options)
    |> from_legacy()
  end

  @doc """
  Builds a POST create request for a company-scoped entity endpoint.
  """
  @spec create([path_segment()] | path_segment(), map(), keyword()) :: t()
  def create(path_segments, body, options \\ []) when is_map(body) do
    path_segments
    |> ExQuickbooks.Request.create(body, options)
    |> from_legacy()
  end

  @doc """
  Builds a POST update request with `operation=update`.
  """
  @spec update([path_segment()] | path_segment(), map(), keyword()) :: t()
  def update(path_segments, body, options \\ []) when is_map(body) do
    path_segments
    |> ExQuickbooks.Request.update(body, options)
    |> from_legacy()
  end

  @doc """
  Builds a POST operation request, such as `void` or `delete`.
  """
  @spec operation([path_segment()] | path_segment(), String.t() | atom(), map(), keyword()) :: t()
  def operation(path_segments, operation_name, body, options \\ []) when is_map(body) do
    path_segments
    |> ExQuickbooks.Request.operation(operation_name, body, options)
    |> from_legacy()
  end

  @doc """
  Builds a POST query request with a plain-text QuickBooks query statement.
  """
  @spec query(String.t(), keyword()) :: t()
  def query(statement, options \\ []) when is_binary(statement) do
    statement
    |> ExQuickbooks.Request.query(options)
    |> from_legacy()
  end

  @doc """
  Builds a POST CDC request.
  """
  @spec cdc([String.t() | atom()] | String.t(), DateTime.t() | String.t(), keyword()) :: t()
  def cdc(entity_names, changed_since, options \\ []) do
    entity_names
    |> ExQuickbooks.Request.cdc(changed_since, options)
    |> from_legacy()
  end

  @doc """
  Builds the company-scoped URL path for a request struct.
  """
  @spec company_url_path(ExQuickBooks.Client.t(), t()) :: String.t()
  def company_url_path(client, request) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Request.company_url_path(ExQuickbooks.PreferredAPI.legacy_request(request))
  end

  @doc """
  Builds a `/v3/company/:realm_id/...` path and appends query parameters.
  """
  @spec company_path(ExQuickBooks.Client.t(), [path_segment()] | path_segment(), keyword()) ::
          String.t()
  def company_path(client, path_segments, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Request.company_path(path_segments, options)
  end

  @doc false
  @spec from_legacy(ExQuickbooks.Request.t()) :: t()
  def from_legacy(%ExQuickbooks.Request{} = request) do
    request
    |> Map.from_struct()
    |> then(&struct(__MODULE__, &1))
  end

  @doc false
  @spec to_legacy(t()) :: ExQuickbooks.Request.t()
  def to_legacy(%__MODULE__{} = request) do
    request
    |> Map.from_struct()
    |> then(&struct(ExQuickbooks.Request, &1))
  end
end

defmodule ExQuickBooks.Config do
  @moduledoc """
  Shared QuickBooks configuration helpers for `ExQuickBooks`.
  """

  @doc """
  Returns the API base URL for a configured client or environment.
  """
  @spec api_base_url(ExQuickBooks.Client.t() | ExQuickBooks.Client.environment()) :: String.t()
  def api_base_url(%ExQuickBooks.Client{} = client) do
    client
    |> ExQuickBooks.Client.to_legacy()
    |> ExQuickbooks.Config.api_base_url()
  end

  def api_base_url(environment) do
    ExQuickbooks.Config.api_base_url(environment)
  end

  @doc """
  Returns the OAuth authorization endpoint.
  """
  @spec oauth_authorization_endpoint() :: String.t()
  def oauth_authorization_endpoint do
    ExQuickbooks.Config.oauth_authorization_endpoint()
  end

  @doc """
  Returns the OAuth token endpoint.
  """
  @spec oauth_token_endpoint() :: String.t()
  def oauth_token_endpoint do
    ExQuickbooks.Config.oauth_token_endpoint()
  end

  @doc """
  Returns default JSON headers and includes bearer auth when an access token exists.
  """
  @spec request_headers(ExQuickBooks.Client.t()) :: [{String.t(), String.t()}]
  def request_headers(client) do
    client
    |> ExQuickBooks.Client.to_legacy()
    |> ExQuickbooks.Config.request_headers()
  end
end

defmodule ExQuickBooks.Response do
  @moduledoc """
  Shared response handling for QuickBooks resource requests.
  """

  @type result :: {:ok, term()} | {:error, ExQuickBooks.Error.t()}

  @doc """
  Parses a QuickBooks response into a success tuple or typed error.
  """
  @spec handle(Req.Response.t(), ExQuickBooks.Request.t()) :: result()
  def handle(response, request) do
    request
    |> ExQuickbooks.PreferredAPI.legacy_request()
    |> then(&ExQuickbooks.Response.handle(response, &1))
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Returns the parsed `Retry-After` header value in seconds when present.
  """
  @spec retry_after_seconds(Req.Response.t()) :: non_neg_integer() | nil
  def retry_after_seconds(response) do
    ExQuickbooks.Response.retry_after_seconds(response)
  end
end

defmodule ExQuickBooks.HTTP do
  @moduledoc """
  Shared Req-based transport for QuickBooks company-scoped requests.
  """

  @type request_option :: ExQuickbooks.HTTP.request_option()

  @doc """
  Executes a shared QuickBooks request.
  """
  @spec request(ExQuickBooks.Client.t(), ExQuickBooks.Request.t(), [request_option()]) ::
          {:ok, term()} | {:error, ExQuickBooks.Error.t()}
  def request(client, request, options \\ []) do
    legacy_client = ExQuickbooks.PreferredAPI.legacy_client(client)
    legacy_request = ExQuickbooks.PreferredAPI.legacy_request(request)

    legacy_client
    |> ExQuickbooks.HTTP.request(legacy_request, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks do
  @moduledoc """
  Public entry points for configuring ExQuickBooks.

  ExQuickBooks is a small Elixir client for the QuickBooks Online Accounting
  API. It focuses on a clear library surface: create a validated client, run
  OAuth flows, execute shared requests, and work with decoded QuickBooks maps.

  ## Examples

      iex> {:ok, %ExQuickBooks.Client{environment: :sandbox}} =
      ...>   ExQuickBooks.new(
      ...>     client_id: "client-id",
      ...>     client_secret: "client-secret",
      ...>     redirect_uri: "https://example.com/callback",
      ...>     realm_id: "9130357992221046"
      ...>   )
  """

  @doc """
  Builds a validated client for later QuickBooks requests.
  """
  @spec new(keyword()) :: {:ok, ExQuickBooks.Client.t()} | {:error, ExQuickBooks.Error.t()}
  def new(options) when is_list(options) do
    ExQuickBooks.Client.new(options)
  end

  @doc """
  Builds a shared `/v3/company/:realm_id/...` request path.

  ## Examples

      iex> {:ok, client} =
      ...>   ExQuickBooks.new(
      ...>     client_id: "client-id",
      ...>     client_secret: "client-secret",
      ...>     redirect_uri: "https://example.com/callback",
      ...>     realm_id: "9130357992221046",
      ...>     minor_version: 75
      ...>   )
      iex> ExQuickBooks.request_path(client, ["customer"], query: [active: true])
      "/v3/company/9130357992221046/customer?active=true&minorversion=75"
  """
  @spec request_path(ExQuickBooks.Client.t(), [String.t() | atom() | integer()], keyword()) ::
          String.t()
  def request_path(client, path_segments, options \\ []) do
    ExQuickBooks.Request.company_path(client, path_segments, options)
  end

  @doc """
  Executes a shared QuickBooks request.
  """
  @spec request(ExQuickBooks.Client.t(), ExQuickBooks.Request.t(), keyword()) ::
          {:ok, term()} | {:error, ExQuickBooks.Error.t()}
  def request(client, request, options \\ []) do
    legacy_client = ExQuickbooks.PreferredAPI.legacy_client(client)
    legacy_request = ExQuickbooks.PreferredAPI.legacy_request(request)

    legacy_client
    |> ExQuickbooks.request(legacy_request, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Auth do
  @moduledoc """
  OAuth 2 helpers for QuickBooks Online.
  """

  @doc """
  Builds the QuickBooks authorization URL.
  """
  @spec authorization_url(keyword()) :: {:ok, String.t()} | {:error, ExQuickBooks.Error.t()}
  def authorization_url(options) when is_list(options) do
    options
    |> ExQuickbooks.Auth.authorization_url()
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Exchanges an authorization code for QuickBooks OAuth tokens.
  """
  @spec exchange_code(keyword()) ::
          {:ok, ExQuickBooks.Token.t()} | {:error, ExQuickBooks.Error.t()}
  def exchange_code(options) when is_list(options) do
    options
    |> ExQuickbooks.Auth.exchange_code()
    |> ExQuickbooks.PreferredAPI.new_token_result()
  end

  @doc """
  Refreshes QuickBooks OAuth tokens using the latest refresh token.
  """
  @spec refresh_tokens(keyword()) ::
          {:ok, ExQuickBooks.Token.t()} | {:error, ExQuickBooks.Error.t()}
  def refresh_tokens(options) when is_list(options) do
    options
    |> ExQuickbooks.Auth.refresh_tokens()
    |> ExQuickbooks.PreferredAPI.new_token_result()
  end
end

defmodule ExQuickBooks.Query do
  @moduledoc """
  Generic query helpers for QuickBooks Online.

  The query helper accepts raw QuickBooks query statements and optionally
  appends `STARTPOSITION` / `MAXRESULTS` clauses for caller-driven pagination.
  """

  @doc """
  Runs a raw QuickBooks query statement.
  """
  @spec run(ExQuickBooks.Client.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def run(client, statement, options \\ []) when is_binary(statement) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Query.run(statement, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Extracts the primary top-level collection from a `QueryResponse` payload.

  ## Examples

      iex> ExQuickBooks.Query.top_level_collection(%{
      ...>   "Customer" => [%{"Id" => "123"}],
      ...>   "startPosition" => 1,
      ...>   "maxResults" => 1
      ...> })
      {:ok, {"Customer", [%{"Id" => "123"}]}}
  """
  @spec top_level_collection(map()) ::
          {:ok, {String.t(), list()}} | {:error, ExQuickBooks.Error.t()}
  def top_level_collection(query_response) when is_map(query_response) do
    query_response
    |> ExQuickbooks.Query.top_level_collection()
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.CDC do
  @moduledoc """
  Change Data Capture helpers for incremental QuickBooks synchronization.

  CDC responses are returned as grouped per-entity maps so callers can process
  changed records and deleted IDs without re-parsing the raw QuickBooks payload.
  """

  @type entity_group :: %{
          records: [map()],
          deleted_ids: [map()]
        }

  @type grouped_changes :: %{
          optional(String.t()) => entity_group()
        }

  @doc """
  Returns the currently supported CDC entity names.

  ## Examples

      iex> "Customer" in ExQuickBooks.CDC.supported_entity_names()
      true
  """
  @spec supported_entity_names() :: [String.t()]
  def supported_entity_names do
    ExQuickbooks.CDC.supported_entity_names()
  end

  @doc """
  Fetches grouped CDC changes since the given checkpoint.
  """
  @spec fetch(
          ExQuickBooks.Client.t(),
          [String.t() | atom()] | String.t() | atom(),
          String.t() | DateTime.t(),
          keyword()
        ) ::
          {:ok, grouped_changes()} | {:error, ExQuickBooks.Error.t()}
  def fetch(client, entity_names, changed_since, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.CDC.fetch(entity_names, changed_since, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Groups a CDC response by entity name and preserves deleted IDs per entity.

  ## Examples

      iex> ExQuickBooks.CDC.group_changes(%{
      ...>   "CDCResponse" => [
      ...>     %{
      ...>       "Customer" => [%{"Id" => "123"}],
      ...>       "DeletedId" => [%{"Type" => "Customer", "Id" => "456"}]
      ...>     }
      ...>   ]
      ...> })
      {:ok,
       %{
         "Customer" => %{
           records: [%{"Id" => "123"}],
           deleted_ids: [%{"Type" => "Customer", "Id" => "456"}]
         }
       }}
  """
  @spec group_changes([map()] | map()) ::
          {:ok, grouped_changes()} | {:error, ExQuickBooks.Error.t()}
  def group_changes(cdc_response) do
    cdc_response
    |> ExQuickbooks.CDC.group_changes()
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.CompanyInfo do
  @moduledoc """
  Read-only access to the QuickBooks company information endpoint.
  """

  @doc """
  Fetches the company information for the configured realm.
  """
  @spec get(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.CompanyInfo.get(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end
