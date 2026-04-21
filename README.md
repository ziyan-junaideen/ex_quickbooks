# ExQuickbooks

ExQuickbooks is an Elixir client for the QuickBooks Online Accounting API.

Phase 1 establishes the project foundation:

- a validated client struct
- shared environment and request path helpers
- typed library error values
- Bypass-based test helpers for asserting request shape

## Installation

Add `ex_quickbooks` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_quickbooks, "~> 0.2.0"}
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
