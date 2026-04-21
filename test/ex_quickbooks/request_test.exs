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

  test "update/3 appends operation=update and preserves response extraction" do
    request =
      ExQuickbooks.Request.update(
        ["invoice"],
        %{"Id" => "10", "SyncToken" => "1"},
        response_path: ["Invoice"]
      )

    assert request.method == :post
    assert request.path_segments == ["invoice"]
    assert request.query == [operation: "update"]
    assert request.body == %{"Id" => "10", "SyncToken" => "1"}
    assert request.response_path == ["Invoice"]
  end

  test "query/2 builds a text request against the query endpoint" do
    request =
      ExQuickbooks.Request.query(
        "SELECT * FROM Customer",
        response_path: ["QueryResponse", "Customer"]
      )

    assert request.method == :post
    assert request.path_segments == ["query"]
    assert request.body == "SELECT * FROM Customer"
    assert request.body_format == :text
    assert request.headers == [{"content-type", "text/plain"}]
    assert request.response_path == ["QueryResponse", "Customer"]
  end

  test "cdc/3 builds a JSON request against the cdc endpoint" do
    request =
      ExQuickbooks.Request.cdc(
        [:Customer, :Invoice],
        ~U[2026-04-21 18:30:00Z]
      )

    assert request.method == :post
    assert request.path_segments == ["cdc"]

    assert request.body == %{
             "entities" => "Customer,Invoice",
             "changedSince" => "2026-04-21T18:30:00Z"
           }

    assert request.response_path == ["CDCResponse"]
  end
end
