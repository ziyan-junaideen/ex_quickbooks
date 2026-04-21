defmodule ExQuickbooks.ClientTest do
  use ExUnit.Case, async: true

  test "new/1 builds a client with sandbox as the default environment" do
    assert {:ok, %ExQuickbooks.Client{} = client} =
             ExQuickbooks.Client.new(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               realm_id: "9130357992221046",
               access_token: "access-token",
               refresh_token: "refresh-token",
               minor_version: 75
             )

    assert client.client_id == "client-id"
    assert client.client_secret == "client-secret"
    assert client.redirect_uri == "https://example.com/callback"
    assert client.realm_id == "9130357992221046"
    assert client.access_token == "access-token"
    assert client.refresh_token == "refresh-token"
    assert client.environment == :sandbox
    assert client.minor_version == 75
  end

  test "new/1 returns a validation error when required options are missing" do
    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Client.new(realm_id: "9130357992221046")

    assert error.type == :validation_failed
    assert error.message =~ "client_id"
  end
end
