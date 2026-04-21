defmodule ExQuickbooks.TokenTest do
  use ExUnit.Case, async: true

  test "from_oauth_response/2 builds token expiry timestamps" do
    current_time = ~U[2026-04-21 18:30:00Z]

    assert {:ok, %ExQuickbooks.Token{} = token} =
             ExQuickbooks.Token.from_oauth_response(
               %{
                 "access_token" => "access-token",
                 "refresh_token" => "refresh-token",
                 "token_type" => "bearer",
                 "expires_in" => 3600,
                 "x_refresh_token_expires_in" => 8_726_400
               },
               current_time: current_time,
               realm_id: "9130357992221046"
             )

    assert token.access_token == "access-token"
    assert token.refresh_token == "refresh-token"
    assert token.token_type == "bearer"
    assert token.expires_in == 3600
    assert token.refresh_token_expires_in == 8_726_400
    assert token.access_token_expires_at == ~U[2026-04-21 19:30:00Z]
    assert token.refresh_token_expires_at == ~U[2026-07-31 18:30:00Z]
    assert token.realm_id == "9130357992221046"
  end

  test "expiry helpers return true once the timestamps have passed" do
    token = %ExQuickbooks.Token{
      access_token: "access-token",
      refresh_token: "refresh-token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token_expires_in: 8_726_400,
      access_token_expires_at: ~U[2026-04-21 19:30:00Z],
      refresh_token_expires_at: ~U[2026-07-31 18:30:00Z],
      realm_id: nil
    }

    refute ExQuickbooks.Token.access_token_expired?(token, ~U[2026-04-21 19:29:59Z])
    assert ExQuickbooks.Token.access_token_expired?(token, ~U[2026-04-21 19:30:00Z])
    refute ExQuickbooks.Token.refresh_token_expired?(token, ~U[2026-07-31 18:29:59Z])
    assert ExQuickbooks.Token.refresh_token_expired?(token, ~U[2026-07-31 18:30:00Z])
  end
end
