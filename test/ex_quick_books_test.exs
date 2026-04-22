defmodule ExQuickBooksTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  doctest ExQuickBooks
  doctest ExQuickBooks.Query
  doctest ExQuickBooks.CDC

  test "new/1 returns the preferred client struct and request_path/3 uses it" do
    assert {:ok, %ExQuickBooks.Client{realm_id: "9130357992221046"} = client} =
             ExQuickBooks.new(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               realm_id: "9130357992221046",
               minor_version: 75
             )

    assert ExQuickBooks.request_path(client, ["customer"], query: [active: true]) ==
             "/v3/company/9130357992221046/customer?active=true&minorversion=75"
  end

  test "request/3 returns the preferred error struct" do
    client = client()
    request = ExQuickBooks.Request.get(["customer", "123"], response_path: ["Customer"])

    assert {:error, %ExQuickBooks.Error{} = error} =
             ExQuickBooks.request(client, request,
               max_retries: 0,
               base_url: "http://127.0.0.1:1"
             )

    assert error.type == :network_error
  end

  test "token helpers return the preferred token struct" do
    assert {:ok, %ExQuickBooks.Token{} = token} =
             ExQuickBooks.Token.from_oauth_response(
               %{
                 "access_token" => "access-token",
                 "refresh_token" => "refresh-token",
                 "token_type" => "bearer",
                 "expires_in" => 3600,
                 "x_refresh_token_expires_in" => 8_726_400
               },
               realm_id: "9130357992221046",
               current_time: ~U[2026-04-21 18:30:00Z]
             )

    assert token.realm_id == "9130357992221046"
    refute ExQuickBooks.Token.access_token_expired?(token, ~U[2026-04-21 19:29:59Z])
    assert ExQuickBooks.Token.access_token_expired?(token, ~U[2026-04-21 19:30:00Z])
  end

  test "auth wrapper returns the preferred token struct" do
    bypass = Bypass.open()
    expected_authorization_header = "Basic " <> Base.encode64("client-id:client-secret")

    Bypass.expect_once(bypass, "POST", "/oauth2/v1/tokens/bearer", fn connection ->
      connection = assert_request(connection, method: :post, url: "/oauth2/v1/tokens/bearer")

      request_headers = Enum.into(connection.req_headers, %{})

      assert Map.get(request_headers, "authorization") == expected_authorization_header

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"access_token":"access-token","refresh_token":"refresh-token","token_type":"bearer","expires_in":3600,"x_refresh_token_expires_in":8726400})
      )
    end)

    assert {:ok, %ExQuickBooks.Token{} = token} =
             ExQuickBooks.Auth.exchange_code(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               code: "authorization-code",
               realm_id: "9130357992221046",
               token_endpoint: "http://localhost:#{bypass.port}/oauth2/v1/tokens/bearer"
             )

    assert token.access_token == "access-token"
    assert token.realm_id == "9130357992221046"
  end

  test "customers wrapper accepts the preferred client struct" do
    bypass = Bypass.open()
    client = client(minor_version: 75)

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/query", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/query?minorversion=75",
          headers: [
            {"authorization", "Bearer access-token"},
            {"accept", "application/json"},
            {"content-type", "text/plain"}
          ],
          body: "SELECT * FROM Customer WHERE Active = true"
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{
          "QueryResponse" => %{
            "Customer" => [%{"Id" => "123", "DisplayName" => "Acme"}]
          }
        })
      )
    end)

    assert {:ok, [%{"Id" => "123", "DisplayName" => "Acme"}]} =
             ExQuickBooks.Customers.list(client,
               where: "Active = true",
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )
  end

  test "query and cdc helpers return the preferred error struct" do
    assert {:error, %ExQuickBooks.Error{} = query_error} =
             ExQuickBooks.Query.top_level_collection(%{})

    assert query_error.type == :api_error

    assert {:error, %ExQuickBooks.Error{} = cdc_error} =
             ExQuickBooks.CDC.group_changes("not-a-cdc-response")

    assert cdc_error.type == :api_error
  end

  defp client(overrides \\ []) do
    assert {:ok, client} =
             ExQuickBooks.new(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               realm_id: "9130357992221046",
               access_token: "access-token",
               refresh_token: "refresh-token",
               environment: :sandbox
             )

    struct(client, Enum.into(overrides, %{}))
  end
end
