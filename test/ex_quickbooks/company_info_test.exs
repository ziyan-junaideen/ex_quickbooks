defmodule ExQuickbooks.CompanyInfoTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "get/2 fetches the configured realm company info" do
    bypass = Bypass.open()
    client = client(minor_version: 75)

    Bypass.expect_once(
      bypass,
      "GET",
      "/v3/company/9130357992221046/companyinfo/9130357992221046",
      fn connection ->
        connection =
          assert_request(connection,
            method: :get,
            url: "/v3/company/9130357992221046/companyinfo/9130357992221046?minorversion=75",
            headers: [
              {"authorization", "Bearer access-token"},
              {"accept", "application/json"},
              {"content-type", "application/json"}
            ],
            body: nil
          )

        connection
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(
          200,
          ~s({"CompanyInfo":{"CompanyName":"Acme LLC","Id":"9130357992221046"}})
        )
      end
    )

    assert {:ok,
            %ExQuickbooks.CompanyInfo{
              id: "9130357992221046",
              company_name: "Acme LLC",
              attributes: %{"CompanyName" => "Acme LLC", "Id" => "9130357992221046"}
            }} =
             ExQuickbooks.CompanyInfo.get(client,
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )
  end

  defp client(options) do
    %ExQuickbooks.Client{
      client_id: "client-id",
      client_secret: "client-secret",
      redirect_uri: "https://example.com/callback",
      realm_id: "9130357992221046",
      access_token: "access-token",
      refresh_token: "refresh-token",
      environment: :sandbox,
      minor_version: Keyword.get(options, :minor_version)
    }
  end
end
