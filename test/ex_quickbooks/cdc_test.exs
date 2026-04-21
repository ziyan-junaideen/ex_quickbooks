defmodule ExQuickbooks.CDCTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  test "fetch/4 builds a CDC request and groups changes by entity" do
    bypass = Bypass.open()
    client = client(minor_version: 75)

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/cdc", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/cdc?minorversion=75",
          headers: [
            {"authorization", "Bearer access-token"},
            {"accept", "application/json"},
            {"content-type", "application/json"}
          ],
          body: %{
            "entities" => "Customer,Invoice",
            "changedSince" => "2026-04-20T00:00:00Z"
          }
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"CDCResponse":[{"Customer":[{"Id":"123"}],"DeletedId":[{"Type":"Customer","Id":"456"}]},{"Invoice":[{"Id":"789"}],"DeletedId":[{"Type":"Invoice","Id":"101"}]}]})
      )
    end)

    assert {:ok, grouped_changes} =
             ExQuickbooks.CDC.fetch(
               client,
               [:customer, :invoice],
               "2026-04-20T00:00:00Z",
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )

    assert grouped_changes["Customer"] == %{
             records: [%{"Id" => "123"}],
             deleted_ids: [%{"Type" => "Customer", "Id" => "456"}]
           }

    assert grouped_changes["Invoice"] == %{
             records: [%{"Id" => "789"}],
             deleted_ids: [%{"Type" => "Invoice", "Id" => "101"}]
           }
  end

  test "fetch/4 preserves requested entity groupings even when there are no changes" do
    bypass = Bypass.open()
    client = client()

    Bypass.expect_once(bypass, "POST", "/v3/company/9130357992221046/cdc", fn connection ->
      connection =
        assert_request(connection,
          method: :post,
          url: "/v3/company/9130357992221046/cdc",
          headers: [{"content-type", "application/json"}],
          body: %{
            "entities" => "Item,Payment",
            "changedSince" => "2026-04-20T00:00:00Z"
          }
        )

      connection
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        ~s({"CDCResponse":[{"Item":[{"Id":"123"}]}]})
      )
    end)

    assert {:ok, grouped_changes} =
             ExQuickbooks.CDC.fetch(
               client,
               [:item, :payment],
               ~U[2026-04-20 00:00:00Z],
               base_url: "http://localhost:#{bypass.port}",
               max_retries: 0
             )

    assert grouped_changes["Item"] == %{
             records: [%{"Id" => "123"}],
             deleted_ids: []
           }

    assert grouped_changes["Payment"] == %{
             records: [],
             deleted_ids: []
           }
  end

  test "group_changes/1 supports nested QueryResponse CDC payloads" do
    assert {:ok, grouped_changes} =
             ExQuickbooks.CDC.group_changes(%{
               "CDCResponse" => [
                 %{
                   "QueryResponse" => [
                     %{"Customer" => [%{"Id" => "123"}]},
                     %{"Invoice" => [%{"Id" => "789"}]}
                   ],
                   "DeletedId" => [
                     %{"Type" => "Invoice", "Id" => "101"}
                   ]
                 }
               ]
             })

    assert grouped_changes["Customer"] == %{
             records: [%{"Id" => "123"}],
             deleted_ids: []
           }

    assert grouped_changes["Invoice"] == %{
             records: [%{"Id" => "789"}],
             deleted_ids: [%{"Type" => "Invoice", "Id" => "101"}]
           }
  end

  test "fetch/4 validates entity names" do
    client = client()

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.CDC.fetch(client, [:customer, :unknown], "2026-04-20T00:00:00Z")

    assert error.type == :validation_failed
    assert error.message =~ "unsupported CDC entity"
  end

  test "fetch/4 validates timestamp formatting" do
    client = client()

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.CDC.fetch(client, [:customer], "2026-04-20")

    assert error.type == :validation_failed
    assert error.message == "changed_since must be an ISO8601 timestamp with timezone"
  end

  test "group_changes/1 returns an error for unexpected payloads" do
    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.CDC.group_changes("invalid")

    assert error.type == :api_error
    assert error.message == "CDC response did not contain grouped entity changes"
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
