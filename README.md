# ExQuickBooks

ExQuickBooks is an Elixir client for the **QuickBooks Online Accounting API**.
It keeps the public API library-oriented and explicit: callers build a client,
run OAuth flows, use resource helpers, and handle expected failures through
`{:ok, result}` / `{:error, %ExQuickBooks.Error{}}` tuples.

The preferred Elixir namespace is `ExQuickBooks`. The legacy `ExQuickbooks`
namespace remains available temporarily for backward compatibility and is
planned for removal at v1.

## Installation

Add `ex_quickbooks` to your dependencies:

```elixir
def deps do
     [
      {:ex_quickbooks, "~> 0.9.0"}
     ]
   end
 ```

## What the library covers

- OAuth 2 authorization URL generation, code exchange, and refresh
- a validated client struct for sandbox or production QuickBooks access
- shared request builders and a Req-based HTTP pipeline
- company bootstrap helpers and generic query support
- resource modules for customers, items, invoices, payments, accounts, and vendors
- CDC helpers for incremental synchronization
- typed errors for validation, auth, rate limiting, API faults, and network failures

## Sandbox setup

1. Create an app in the [Intuit Developer portal](https://developer.intuit.com/).
2. In **Keys & OAuth**, copy your **Client ID** and **Client Secret**.
3. Add a local redirect URI such as `http://localhost:4000/auth/quickbooks/callback`.
4. Open the sandbox company provided in your developer dashboard and note its `realmId`.
5. Use the `com.intuit.quickbooks.accounting` scope during OAuth.

Useful references:

- [Intuit OAuth 2.0 docs](https://developer.intuit.com/app/developer/qbo/docs/develop/authentication-and-authorization/oauth-2.0)
- [Intuit sandbox docs](https://developer.intuit.com/app/developer/qbo/docs/develop/sandboxes)
- [QuickBooks Online quick start](https://developer.intuit.com/app/developer/qbo/docs/get-started/quick-start)

## OAuth usage

Generate the authorization URL:

```elixir
{:ok, authorization_url} =
  ExQuickBooks.Auth.authorization_url(
    client_id: "client-id",
    redirect_uri: "http://localhost:4000/auth/quickbooks/callback",
    state: "csrf-token"
  )
```

Exchange the callback code for tokens:

```elixir
{:ok, token} =
  ExQuickBooks.Auth.exchange_code(
    client_id: "client-id",
    client_secret: "client-secret",
    redirect_uri: "http://localhost:4000/auth/quickbooks/callback",
    code: "authorization-code",
    realm_id: "9130357992221046"
  )
```

Refresh tokens with the latest refresh token returned by Intuit:

```elixir
{:ok, refreshed_token} =
  ExQuickBooks.Auth.refresh_tokens(
    client_id: "client-id",
    client_secret: "client-secret",
    refresh_token: token.refresh_token,
    realm_id: token.realm_id
  )
```

## Basic client creation

Construct a client once you have tokens:

```elixir
{:ok, client} =
  ExQuickBooks.new(
    client_id: "client-id",
    client_secret: "client-secret",
    redirect_uri: "http://localhost:4000/auth/quickbooks/callback",
    realm_id: token.realm_id,
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    environment: :sandbox,
    minor_version: 75
  )
```

You can use `ExQuickBooks.request_path/3` to inspect the company-scoped request
path that the shared HTTP pipeline will use:

```elixir
ExQuickBooks.request_path(client, ["customer"], query: [active: true])
#=> "/v3/company/9130357992221046/customer?active=true&minorversion=75"
```

## Company bootstrap and query helpers

Confirm the client can reach the target company:

```elixir
{:ok, company_info} = ExQuickBooks.CompanyInfo.get(client)
```

Run raw QuickBooks queries with optional pagination:

```elixir
{:ok, query_response} =
  ExQuickBooks.Query.run(
    client,
    "SELECT * FROM Customer",
    start_position: 1,
    max_results: 25
  )

{:ok, {"Customer", customers}} =
  ExQuickBooks.Query.top_level_collection(query_response)
```

## Customer and invoice flows

Fetch active customers:

```elixir
{:ok, customers} =
  ExQuickBooks.Customers.list(
    client,
    where: "Active = true",
    max_results: 25
  )
```

Create and update a customer:

```elixir
{:ok, created_customer} =
  ExQuickBooks.Customers.create(client, %{
    "DisplayName" => "Acme"
  })

{:ok, updated_customer} =
  ExQuickBooks.Customers.update(client, %{
    "Id" => created_customer["Id"],
    "SyncToken" => created_customer["SyncToken"],
    "DisplayName" => "Acme Updated"
  })
```

Create and update an invoice:

```elixir
{:ok, created_invoice} =
  ExQuickBooks.Invoices.create(client, %{
    "CustomerRef" => %{"value" => created_customer["Id"]},
    "Line" => [
      %{
        "Amount" => 100,
        "DetailType" => "SalesItemLineDetail"
      }
    ]
  })

{:ok, updated_invoice} =
  ExQuickBooks.Invoices.update(client, %{
    "Id" => created_invoice["Id"],
    "SyncToken" => created_invoice["SyncToken"],
    "PrivateNote" => "Updated through ExQuickbooks"
  })
```

The same `list/2`, `get/3`, `create/3`, and `update/3` pattern is available for:

- `ExQuickBooks.Items`
- `ExQuickBooks.Payments`
- `ExQuickBooks.Accounts`
- `ExQuickBooks.Vendors`

## CDC sync helpers

Fetch grouped changes since a checkpoint:

```elixir
{:ok, customer_changes} =
  ExQuickBooks.CDC.fetch(
    client,
    [:customer],
    "2026-04-20T00:00:00Z"
  )

{:ok, item_changes} =
  ExQuickBooks.CDC.fetch(
    client,
    [:item],
    "2026-04-20T00:00:00Z"
  )

{:ok, invoice_and_payment_changes} =
  ExQuickBooks.CDC.fetch(
    client,
    [:invoice, :payment],
    "2026-04-20T00:00:00Z"
  )
```

Each entity key maps to grouped records and deleted IDs:

```elixir
%{
  "Customer" => %{
    records: [%{"Id" => "123"}],
    deleted_ids: [%{"Type" => "Customer", "Id" => "456"}]
  }
}
```

## Error handling

The library returns typed `ExQuickbooks.Error` values for expected failures:

```elixir
case ExQuickbooks.Customers.get(client, "123") do
  {:ok, customer} ->
    {:ok, customer}

  {:error, %ExQuickbooks.Error{type: :not_found}} ->
    {:error, :missing_customer}

  {:error, %ExQuickbooks.Error{type: :rate_limited, details: %{"retry_after" => retry_after}}} ->
    {:error, {:retry_later, retry_after}}

  {:error, %ExQuickbooks.Error{type: :unauthorized}} ->
    {:error, :refresh_required}

  {:error, %ExQuickbooks.Error{} = error} ->
    {:error, error}
end
```

## Versioning strategy

ExQuickbooks is still pre-`1.0`, so versioning is conservative:

- additive endpoint and helper support bumps the **minor** version (`0.x`)
- bug fixes and documentation-only updates bump the **patch** version
- breaking API changes will use the next pre-`1.0` minor version, and then move
  to normal SemVer major releases once the package reaches `1.0`
