defmodule ExQuickbooks.RequestTest do
  use ExUnit.Case, async: true

  test "company_path/3 builds the shared company path and appends the minor version" do
    client = %ExQuickbooks.Client{
      client_id: "client-id",
      client_secret: "client-secret",
      redirect_uri: "https://example.com/callback",
      realm_id: "9130357992221046",
      access_token: nil,
      refresh_token: nil,
      environment: :sandbox,
      minor_version: 75
    }

    assert ExQuickbooks.Request.company_path(client, ["customer"], query: [active: true]) ==
             "/v3/company/9130357992221046/customer?active=true&minorversion=75"
  end

  test "request_path/3 supports atom and integer segments" do
    client = %ExQuickbooks.Client{
      client_id: "client-id",
      client_secret: "client-secret",
      redirect_uri: "https://example.com/callback",
      realm_id: "9130357992221046",
      access_token: nil,
      refresh_token: nil,
      environment: :sandbox,
      minor_version: nil
    }

    assert ExQuickbooks.request_path(client, [:invoice, 123]) ==
             "/v3/company/9130357992221046/invoice/123"
  end
end
