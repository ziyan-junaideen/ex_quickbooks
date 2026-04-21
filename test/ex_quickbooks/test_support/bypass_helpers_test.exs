defmodule ExQuickbooks.TestSupport.BypassHelpersTest do
  use ExUnit.Case, async: true

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "assert_request/2 checks request method, url, headers, and body" do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/customer", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/customer?minorversion=75",
          headers: [
            {"authorization", "Bearer access-token"},
            {"content-type", "application/json"}
          ],
          body: %{"DisplayName" => "Acme"}
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, ~s({"Customer":{"Id":"1"}}))
    end)

    response =
      Req.post!(
        "http://localhost:#{bypass.port}/v3/company/9130357992221046/customer",
        params: [minorversion: 75],
        headers: [
          {"authorization", "Bearer access-token"},
          {"content-type", "application/json"}
        ],
        json: %{"DisplayName" => "Acme"}
      )

    assert response.status == 200
    assert response.body == %{"Customer" => %{"Id" => "1"}}
  end
end
