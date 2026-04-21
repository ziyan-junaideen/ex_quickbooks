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
end
