# ExQuickbooks

ExQuickbooks is an Elixir client for the QuickBooks Online Accounting API.

The library currently includes:

- a validated client struct
- shared environment, request builders, and an HTTP pipeline
- typed library error values
- OAuth 2 helpers for authorization URL generation, code exchange, and refresh
- Bypass-based test helpers for asserting request shape

## Installation

Add `ex_quickbooks` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_quickbooks, "~> 0.4.0"}
  ]
end
```

## Foundation usage

```elixir
{:ok, client} =
  ExQuickbooks.new(
    client_id: "client-id",
    client_secret: "client-secret",
    redirect_uri: "https://example.com/callback",
    realm_id: "9130357992221046",
    access_token: "access-token",
    refresh_token: "refresh-token",
    environment: :sandbox,
    minor_version: 75
  )

ExQuickbooks.request_path(client, ["customer"], query: [active: true])
#=> "/v3/company/9130357992221046/customer?active=true&minorversion=75"
```

## Shared HTTP pipeline

Build a request with the shared request helpers and execute it through the
common transport pipeline:

```elixir
customer_request =
  ExQuickbooks.Request.get(
    ["customer", "123"],
    response_path: ["Customer"]
  )

{:ok, customer} = ExQuickbooks.request(client, customer_request)
```

The shared request helpers cover the common QuickBooks request shapes:

```elixir
ExQuickbooks.Request.create(["customer"], %{"DisplayName" => "Acme"}, response_path: ["Customer"])
ExQuickbooks.Request.update(["invoice"], %{"Id" => "10", "SyncToken" => "1"}, response_path: ["Invoice"])
ExQuickbooks.Request.operation(["invoice"], :void, %{"Id" => "10", "SyncToken" => "1"}, response_path: ["Invoice"])
ExQuickbooks.Request.query("SELECT * FROM Customer")
ExQuickbooks.Request.cdc(["Customer", "Invoice"], "2026-04-20T00:00:00Z")
```

The HTTP pipeline automatically:

- injects bearer auth from the client
- selects the sandbox or production QuickBooks host
- appends `minorversion` when configured on the client
- decodes JSON responses
- parses QuickBooks `Fault` responses into typed `ExQuickbooks.Error` values
- retries `429`, `500`, `502`, `503`, and `504` responses, honoring `Retry-After`

## OAuth 2

Generate the authorization URL:

```elixir
{:ok, authorization_url} =
  ExQuickbooks.Auth.authorization_url(
    client_id: "client-id",
    redirect_uri: "https://example.com/callback",
    state: "csrf-token"
  )
```

Exchange the callback code for tokens:

```elixir
{:ok, token} =
  ExQuickbooks.Auth.exchange_code(
    client_id: "client-id",
    client_secret: "client-secret",
    redirect_uri: "https://example.com/callback",
    code: "authorization-code",
    realm_id: "9130357992221046"
  )
```

Use the returned token values when constructing a client:

```elixir
{:ok, client} =
  ExQuickbooks.new(
    client_id: "client-id",
    client_secret: "client-secret",
    redirect_uri: "https://example.com/callback",
    realm_id: token.realm_id,
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    environment: :sandbox
  )
```

Refresh tokens with the latest refresh token and persist the replacement refresh
token from the response:

```elixir
{:ok, refreshed_token} =
  ExQuickbooks.Auth.refresh_tokens(
    client_id: "client-id",
    client_secret: "client-secret",
    refresh_token: token.refresh_token,
    realm_id: token.realm_id
  )
```

You can check token expiry with `ExQuickbooks.Token.access_token_expired?/2` and
`ExQuickbooks.Token.refresh_token_expired?/2`.
