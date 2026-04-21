defmodule ExQuickbooks.AuthTest do
  use ExUnit.Case, async: true

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "authorization_url/1 builds the QuickBooks OAuth authorization URL" do
    assert {:ok, authorization_url} =
             ExQuickbooks.Auth.authorization_url(
               client_id: "client-id",
               redirect_uri: "https://example.com/callback",
               scopes: ["com.intuit.quickbooks.accounting", "openid"],
               state: "csrf-token"
             )

    parsed_url = URI.parse(authorization_url)
    query_parameters = URI.decode_query(parsed_url.query)

    assert parsed_url.scheme == "https"
    assert parsed_url.host == "appcenter.intuit.com"
    assert parsed_url.path == "/connect/oauth2"
    assert query_parameters["client_id"] == "client-id"
    assert query_parameters["redirect_uri"] == "https://example.com/callback"
    assert query_parameters["response_type"] == "code"
    assert query_parameters["scope"] == "com.intuit.quickbooks.accounting openid"
    assert query_parameters["state"] == "csrf-token"
  end

  test "authorization_url/1 defaults to the QuickBooks accounting scope" do
    assert {:ok, authorization_url} =
             ExQuickbooks.Auth.authorization_url(
               client_id: "client-id",
               redirect_uri: "https://example.com/callback"
             )

    query_parameters =
      authorization_url
      |> URI.parse()
      |> Map.fetch!(:query)
      |> URI.decode_query()

    assert query_parameters["scope"] == "com.intuit.quickbooks.accounting"
  end

  test "exchange_code/1 posts the authorization code request and parses token data" do
    bypass = Bypass.open()
    expected_authorization_header = "Basic " <> Base.encode64("client-id:client-secret")

    Bypass.expect_once(bypass, "POST", "/oauth2/v1/tokens/bearer", fn connection ->
      connection = assert_request(connection, method: :post, url: "/oauth2/v1/tokens/bearer")

      request_headers = Enum.into(connection.req_headers, %{})

      assert Map.get(request_headers, "authorization") == expected_authorization_header

      assert String.starts_with?(
               Map.get(request_headers, "content-type"),
               "application/x-www-form-urlencoded"
             )

      {:ok, request_body, connection} = Plug.Conn.read_body(connection)

      assert URI.decode_query(request_body) == %{
               "grant_type" => "authorization_code",
               "code" => "authorization-code",
               "redirect_uri" => "https://example.com/callback"
             }

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"access_token":"access-token","refresh_token":"refresh-token","token_type":"bearer","expires_in":3600,"x_refresh_token_expires_in":8726400})
      )
    end)

    assert {:ok, %ExQuickbooks.Token{} = token} =
             ExQuickbooks.Auth.exchange_code(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               code: "authorization-code",
               realm_id: "9130357992221046",
               token_endpoint: "http://localhost:#{bypass.port}/oauth2/v1/tokens/bearer"
             )

    assert token.access_token == "access-token"
    assert token.refresh_token == "refresh-token"
    assert token.realm_id == "9130357992221046"
  end

  test "refresh_tokens/1 posts the refresh token request and returns the rotated token" do
    bypass = Bypass.open()
    expected_authorization_header = "Basic " <> Base.encode64("client-id:client-secret")

    Bypass.expect_once(bypass, "POST", "/oauth2/v1/tokens/bearer", fn connection ->
      connection = assert_request(connection, method: :post, url: "/oauth2/v1/tokens/bearer")

      request_headers = Enum.into(connection.req_headers, %{})

      assert Map.get(request_headers, "authorization") == expected_authorization_header

      {:ok, request_body, connection} = Plug.Conn.read_body(connection)

      assert URI.decode_query(request_body) == %{
               "grant_type" => "refresh_token",
               "refresh_token" => "refresh-token"
             }

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"access_token":"new-access-token","refresh_token":"rotated-refresh-token","token_type":"bearer","expires_in":3600,"x_refresh_token_expires_in":8726400})
      )
    end)

    assert {:ok, %ExQuickbooks.Token{} = token} =
             ExQuickbooks.Auth.refresh_tokens(
               client_id: "client-id",
               client_secret: "client-secret",
               refresh_token: "refresh-token",
               realm_id: "9130357992221046",
               token_endpoint: "http://localhost:#{bypass.port}/oauth2/v1/tokens/bearer"
             )

    assert token.access_token == "new-access-token"
    assert token.refresh_token == "rotated-refresh-token"
    assert token.realm_id == "9130357992221046"
  end

  test "exchange_code/1 translates invalid_grant into an unauthorized error" do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "POST", "/oauth2/v1/tokens/bearer", fn connection ->
      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        400,
        ~s({"error":"invalid_grant","error_description":"The refresh token is invalid or expired"})
      )
    end)

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Auth.exchange_code(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               code: "authorization-code",
               token_endpoint: "http://localhost:#{bypass.port}/oauth2/v1/tokens/bearer"
             )

    assert error.type == :unauthorized
    assert error.status == 400
    assert error.message == "The refresh token is invalid or expired"
    assert error.details["error"] == "invalid_grant"
  end

  test "refresh_tokens/1 translates invalid_client into an unauthorized error" do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "POST", "/oauth2/v1/tokens/bearer", fn connection ->
      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        401,
        ~s({"error":"invalid_client","error_description":"Client Authentication failed"})
      )
    end)

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Auth.refresh_tokens(
               client_id: "client-id",
               client_secret: "wrong-secret",
               refresh_token: "refresh-token",
               token_endpoint: "http://localhost:#{bypass.port}/oauth2/v1/tokens/bearer"
             )

    assert error.type == :unauthorized
    assert error.status == 401
    assert error.message == "Client Authentication failed"
    assert error.details["error"] == "invalid_client"
  end
end
