# ExQuickbooks

ExQuickbooks is an Elixir client for the QuickBooks Online Accounting API.

The library currently includes:

- a validated client struct
- shared environment and request path helpers
- typed library error values
- OAuth 2 helpers for authorization URL generation, code exchange, and refresh
- Bypass-based test helpers for asserting request shape

## Installation

Add `ex_quickbooks` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_quickbooks, "~> 0.3.0"}
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
