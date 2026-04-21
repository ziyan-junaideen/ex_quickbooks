defmodule ExQuickbooks.QueryTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "run/3 appends pagination clauses and returns normalized QueryResponse" do
    bypass = Bypass.open()
    client = client()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/query", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/query",
          headers: [
            {"authorization", "Bearer access-token"},
            {"accept", "application/json"},
            {"content-type", "text/plain"}
          ],
          body: "SELECT * FROM Customer STARTPOSITION 10 MAXRESULTS 25"
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"QueryResponse":{"Customer":[{"Id":"123"}],"startPosition":10,"maxResults":25}})
      )
    end)

    assert {:ok,
            %{
              "Customer" => [
                %ExQuickbooks.Customer{id: "123", attributes: %{"Id" => "123"}}
              ],
              "startPosition" => 10,
              "maxResults" => 25
            }} =
             ExQuickbooks.Query.run(
               client,
               "SELECT * FROM Customer",
               start_position: 10,
               max_results: 25,
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )
  end

  test "run/3 preserves caller-supplied pagination clauses" do
    bypass = Bypass.open()
    client = client()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/query", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/query",
          headers: [{"content-type", "text/plain"}],
          body: "SELECT * FROM CompanyInfo STARTPOSITION 1 MAXRESULTS 1"
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"QueryResponse":{"CompanyInfo":[{"CompanyName":"Acme LLC"}],"startPosition":1,"maxResults":1}})
      )
    end)

    assert {:ok, query_response} =
             ExQuickbooks.Query.run(
               client,
               "SELECT * FROM CompanyInfo STARTPOSITION 1 MAXRESULTS 1",
               start_position: 10,
               max_results: 25,
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )

    assert query_response["CompanyInfo"] == [
             %ExQuickbooks.CompanyInfo{
               company_name: "Acme LLC",
               attributes: %{"CompanyName" => "Acme LLC"}
             }
           ]
  end

  test "top_level_collection/1 extracts the primary normalized collection from QueryResponse" do
    assert {:ok, {"Customer", [%ExQuickbooks.Customer{id: "123"}]}} =
             ExQuickbooks.Query.top_level_collection(%{
               "Customer" => [%ExQuickbooks.Customer{id: "123", attributes: %{"Id" => "123"}}],
               "startPosition" => 1,
               "maxResults" => 1
             })
  end

  test "run/3 preserves unknown collection payloads as maps" do
    bypass = Bypass.open()
    client = client()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/query", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/query",
          headers: [{"content-type", "text/plain"}],
          body: "SELECT * FROM Attachable"
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, ~s({"QueryResponse":{"Attachable":[{"Id":"123"}]}}))
    end)

    assert {:ok, %{"Attachable" => [%{"Id" => "123"}]}} =
             ExQuickbooks.Query.run(
               client,
               "SELECT * FROM Attachable",
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )
  end

  test "top_level_collection/1 returns an error when there is no top-level collection" do
    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Query.top_level_collection(%{
               "startPosition" => 1,
               "maxResults" => 0
             })

    assert error.type == :api_error
    assert error.message == "Query response did not contain a top-level collection"
  end

  test "run/3 validates pagination options" do
    client = client()

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Query.run(client, "SELECT * FROM Customer", max_results: 0)

    assert error.type == :validation_failed
    assert error.message =~ "max_results"
  end

  defp client do
    %ExQuickbooks.Client{
      client_id: "client-id",
      client_secret: "client-secret",
      redirect_uri: "https://example.com/callback",
      realm_id: "9130357992221046",
      access_token: "access-token",
      refresh_token: "refresh-token",
      environment: :sandbox,
      minor_version: nil
    }
  end
end
