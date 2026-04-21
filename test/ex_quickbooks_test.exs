defmodule ExQuickbooksTest do
  use ExUnit.Case, async: true

  doctest ExQuickbooks

  test "new/1 delegates to the client builder" do
    assert {:ok, %ExQuickbooks.Client{realm_id: "9130357992221046"}} =
             ExQuickbooks.new(
               client_id: "client-id",
               client_secret: "client-secret",
               redirect_uri: "https://example.com/callback",
               realm_id: "9130357992221046"
             )
  end

  test "request/3 delegates to the shared HTTP pipeline" do
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

    request = ExQuickbooks.Request.get(["customer", "123"], response_path: ["Customer"])

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.request(client, request,
               max_retries: 0,
               base_url: "http://127.0.0.1:1"
             )

    assert error.type == :network_error
  end
end
