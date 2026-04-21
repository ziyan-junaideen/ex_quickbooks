defmodule ExQuickbooks.HTTPTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "request/3 injects bearer auth, uses the company path, and extracts the response payload" do
    bypass = Bypass.open()
    client = client(minor_version: 75)

    Bypass.expect_once(
      bypass,
      "GET",
      "/v3/company/9130357992221046/customer/123",
      fn connection ->
        connection =
          assert_request(connection,
            method: :get,
            url: "/v3/company/9130357992221046/customer/123?minorversion=75",
            headers: [
              {"authorization", "Bearer access-token"},
              {"accept", "application/json"},
              {"content-type", "application/json"}
            ],
            body: nil
          )

        connection
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"Customer":{"Id":"123","DisplayName":"Acme"}}))
      end
    )

    request = ExQuickbooks.Request.get(["customer", "123"], response_path: ["Customer"])

    assert {:ok,
            %ExQuickbooks.Customer{
              id: "123",
              display_name: "Acme",
              attributes: %{"Id" => "123", "DisplayName" => "Acme"}
            }} =
             ExQuickbooks.request(client, request,
               max_retries: 0,
               base_url: "http://localhost:#{bypass.port}"
             )
  end

  test "request/3 sends query requests as text/plain and extracts QueryResponse" do
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
          body: "SELECT * FROM Customer"
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, ~s({"QueryResponse":{"Customer":[{"Id":"123"}]}}))
    end)

    request = ExQuickbooks.Request.query("SELECT * FROM Customer")

    assert {:ok,
            %{
              "Customer" => [
                %ExQuickbooks.Customer{id: "123", attributes: %{"Id" => "123"}}
              ]
            }} =
             ExQuickbooks.request(client, request,
               max_retries: 0,
               base_url: "http://localhost:#{bypass.port}"
             )
  end

  test "request/3 parses QuickBooks Fault validation errors" do
    bypass = Bypass.open()
    client = client()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/customer", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/customer",
          headers: [{"authorization", "Bearer access-token"}],
          body: %{"DisplayName" => ""}
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        400,
        ~s({"Fault":{"Error":[{"Message":"Validation Exception","Detail":"DisplayName is required","code":"2010","element":"DisplayName"}],"type":"ValidationFault"},"time":"2026-04-21T18:30:00.000Z"})
      )
    end)

    request =
      ExQuickbooks.Request.create(
        ["customer"],
        %{"DisplayName" => ""},
        response_path: ["Customer"]
      )

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.request(client, request,
               max_retries: 0,
               base_url: "http://localhost:#{bypass.port}"
             )

    assert error.type == :validation_failed
    assert error.status == 400
    assert error.message == "DisplayName is required"
    assert error.details["Fault"]["type"] == "ValidationFault"
  end

  test "request/3 retries 429 responses and honors Retry-After" do
    bypass = Bypass.open()
    client = client()
    request_attempts = :counters.new(1, [])

    Bypass.expect(bypass, "GET", "/v3/company/9130357992221046/customer/123", fn connection ->
      :counters.add(request_attempts, 1, 1)

      case :counters.get(request_attempts, 1) do
        1 ->
          connection
          |> Plug.Conn.put_resp_header("retry-after", "0")
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(
            429,
            ~s({"Fault":{"Error":[{"Message":"Rate limit exceeded","Detail":"Retry later","code":"429"}],"type":"Fault"},"time":"2026-04-21T18:30:00.000Z"})
          )

        _subsequent_attempt ->
          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, ~s({"Customer":{"Id":"123"}}))
      end
    end)

    request = ExQuickbooks.Request.get(["customer", "123"], response_path: ["Customer"])

    assert {:ok, %ExQuickbooks.Customer{id: "123", attributes: %{"Id" => "123"}}} =
             ExQuickbooks.request(
               client,
               request,
               max_retries: 1,
               sleep_function: fn _retry_delay_ms -> :ok end,
               base_url: "http://localhost:#{bypass.port}"
             )

    assert :counters.get(request_attempts, 1) == 2
  end

  test "request/3 retries selected 5xx responses" do
    bypass = Bypass.open()
    client = client()
    request_attempts = :counters.new(1, [])

    Bypass.expect(bypass, "POST", "/v3/company/9130357992221046/query", fn connection ->
      :counters.add(request_attempts, 1, 1)

      case :counters.get(request_attempts, 1) do
        1 ->
          connection
          |> Plug.Conn.put_resp_header("retry-after", "0")
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(
            503,
            ~s({"Fault":{"Error":[{"Message":"Service unavailable"}],"type":"SystemFault"}})
          )

        _subsequent_attempt ->
          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, ~s({"QueryResponse":{"Customer":[]}}))
      end
    end)

    request = ExQuickbooks.Request.query("SELECT * FROM Customer")

    assert {:ok, %{"Customer" => []}} =
             ExQuickbooks.request(
               client,
               request,
               max_retries: 1,
               sleep_function: fn _retry_delay_ms -> :ok end,
               base_url: "http://localhost:#{bypass.port}"
             )

    assert :counters.get(request_attempts, 1) == 2
  end

  test "request/3 does not retry unauthorized responses" do
    bypass = Bypass.open()
    client = client()
    request_attempts = :counters.new(1, [])

    Bypass.expect(bypass, "GET", "/v3/company/9130357992221046/customer/123", fn connection ->
      :counters.add(request_attempts, 1, 1)

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        401,
        ~s({"Fault":{"Error":[{"Message":"Authentication failed","Detail":"Token expired","code":"3200"}],"type":"AuthenticationFault"}})
      )
    end)

    request = ExQuickbooks.Request.get(["customer", "123"], response_path: ["Customer"])

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.request(
               client,
               request,
               max_retries: 2,
               sleep_function: fn _retry_delay_ms -> :ok end,
               base_url: "http://localhost:#{bypass.port}"
             )

    assert error.type == :unauthorized
    assert error.status == 401
    assert error.message == "Token expired"
    assert :counters.get(request_attempts, 1) == 1
  end

  defp client(options \\ []) do
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
