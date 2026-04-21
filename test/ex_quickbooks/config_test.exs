defmodule ExQuickbooks.ConfigTest do
  use ExUnit.Case, async: true

  test "api_base_url/1 returns the environment-specific QuickBooks host" do
    assert ExQuickbooks.Config.api_base_url(:sandbox) ==
             "https://sandbox-quickbooks.api.intuit.com"

    assert ExQuickbooks.Config.api_base_url(:production) ==
             "https://quickbooks.api.intuit.com"
  end

  test "request_headers/1 includes bearer auth when an access token is configured" do
    client = %ExQuickbooks.Client{
      client_id: "client-id",
      client_secret: "client-secret",
      redirect_uri: "https://example.com/callback",
      realm_id: "9130357992221046",
      access_token: "access-token",
      refresh_token: nil,
      environment: :sandbox,
      minor_version: nil
    }

    assert ExQuickbooks.Config.request_headers(client) == [
             {"authorization", "Bearer access-token"},
             {"accept", "application/json"},
             {"content-type", "application/json"}
           ]
  end
end
