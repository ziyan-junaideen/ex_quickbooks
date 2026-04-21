defmodule ExQuickbooks.ResourcesTest do
  use ExUnit.Case, async: false

  import ExQuickbooks.TestSupport.BypassHelpers, only: [assert_request: 2]

  @resource_definitions [
    %{
      module: ExQuickbooks.Customers,
      struct_module: ExQuickbooks.Customer,
      path: "customer",
      response_name: "Customer",
      list_response: [%{"Id" => "123", "DisplayName" => "Acme"}],
      create_attributes: %{"DisplayName" => "Acme"},
      create_response: %{"Id" => "123", "SyncToken" => "0", "DisplayName" => "Acme"},
      update_attributes: %{"Id" => "123", "SyncToken" => "1", "DisplayName" => "Acme Updated"}
    },
    %{
      module: ExQuickbooks.Items,
      struct_module: ExQuickbooks.Item,
      path: "item",
      response_name: "Item",
      list_response: [%{"Id" => "123", "Name" => "Widget"}],
      create_attributes: %{"Name" => "Widget"},
      create_response: %{"Id" => "123", "SyncToken" => "0", "Name" => "Widget"},
      update_attributes: %{"Id" => "123", "SyncToken" => "1", "Name" => "Widget Updated"}
    },
    %{
      module: ExQuickbooks.Invoices,
      struct_module: ExQuickbooks.Invoice,
      path: "invoice",
      response_name: "Invoice",
      list_response: [%{"Id" => "123", "DocNumber" => "INV-001"}],
      create_attributes: %{"Line" => [%{"Amount" => 100}]},
      create_response: %{"Id" => "123", "SyncToken" => "0", "DocNumber" => "INV-001"},
      update_attributes: %{"Id" => "123", "SyncToken" => "1", "DocNumber" => "INV-001-UPDATED"}
    },
    %{
      module: ExQuickbooks.Payments,
      struct_module: ExQuickbooks.Payment,
      path: "payment",
      response_name: "Payment",
      list_response: [%{"Id" => "123", "TotalAmt" => 100}],
      create_attributes: %{"TotalAmt" => 100},
      create_response: %{"Id" => "123", "SyncToken" => "0", "TotalAmt" => 100},
      update_attributes: %{"Id" => "123", "SyncToken" => "1", "PrivateNote" => "Updated payment"}
    },
    %{
      module: ExQuickbooks.Accounts,
      struct_module: ExQuickbooks.Account,
      path: "account",
      response_name: "Account",
      list_response: [%{"Id" => "123", "Name" => "Sales"}],
      create_attributes: %{"Name" => "Sales", "AccountType" => "Income"},
      create_response: %{"Id" => "123", "SyncToken" => "0", "Name" => "Sales"},
      update_attributes: %{"Id" => "123", "SyncToken" => "1", "Name" => "Sales Updated"}
    },
    %{
      module: ExQuickbooks.Vendors,
      struct_module: ExQuickbooks.Vendor,
      path: "vendor",
      response_name: "Vendor",
      list_response: [%{"Id" => "123", "DisplayName" => "Acme Vendor"}],
      create_attributes: %{"DisplayName" => "Acme Vendor"},
      create_response: %{"Id" => "123", "SyncToken" => "0", "DisplayName" => "Acme Vendor"},
      update_attributes: %{
        "Id" => "123",
        "SyncToken" => "1",
        "DisplayName" => "Acme Vendor Updated"
      }
    }
  ]

  for resource_definition <- @resource_definitions do
    test "#{inspect(resource_definition.module)}.list/2 returns the resource collection" do
      resource_definition = unquote(Macro.escape(resource_definition))
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
            body:
              "SELECT * FROM #{resource_definition.response_name} WHERE Id = '123' STARTPOSITION 10 MAXRESULTS 25"
          )

        response_body =
          Jason.encode!(%{
            "QueryResponse" => %{
              resource_definition.response_name => resource_definition.list_response,
              "startPosition" => 10,
              "maxResults" => 25
            }
          })

        connection
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      assert {:ok, returned_collection} =
               resource_definition.module.list(client,
                 where: "Id = '123'",
                 start_position: 10,
                 max_results: 25,
                 base_url: "http://localhost:#{bypass.port}",
                 max_retries: 0
               )

      assert Enum.map(returned_collection, & &1.attributes) == resource_definition.list_response
      assert Enum.all?(returned_collection, &(&1.__struct__ == resource_definition.struct_module))
    end

    test "#{inspect(resource_definition.module)}.get/3 fetches the resource by id" do
      resource_definition = unquote(Macro.escape(resource_definition))
      bypass = Bypass.open()
      client = client(minor_version: 75)

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/company/9130357992221046/#{resource_definition.path}/123",
        fn connection ->
          connection =
            assert_request(connection,
              method: :get,
              url: "/v3/company/9130357992221046/#{resource_definition.path}/123?minorversion=75",
              headers: [
                {"authorization", "Bearer access-token"},
                {"accept", "application/json"},
                {"content-type", "application/json"}
              ],
              body: nil
            )

          response_body =
            Jason.encode!(%{
              resource_definition.response_name => hd(resource_definition.list_response)
            })

          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, response_body)
        end
      )

      assert {:ok, returned_resource} =
               resource_definition.module.get(client, "123",
                 base_url: "http://localhost:#{bypass.port}",
                 max_retries: 0
               )

      assert returned_resource.attributes == hd(resource_definition.list_response)
      assert returned_resource.__struct__ == resource_definition.struct_module
    end

    test "#{inspect(resource_definition.module)}.create/3 posts the create payload" do
      resource_definition = unquote(Macro.escape(resource_definition))
      bypass = Bypass.open()
      client = client()

      Bypass.expect_once(
        bypass,
        "POST",
        "/v3/company/9130357992221046/#{resource_definition.path}",
        fn connection ->
          connection =
            assert_request(connection,
              method: :post,
              url: "/v3/company/9130357992221046/#{resource_definition.path}",
              headers: [{"authorization", "Bearer access-token"}],
              body: resource_definition.create_attributes
            )

          response_body =
            Jason.encode!(%{
              resource_definition.response_name => resource_definition.create_response
            })

          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, response_body)
        end
      )

      assert {:ok, returned_resource} =
               resource_definition.module.create(client, resource_definition.create_attributes,
                 base_url: "http://localhost:#{bypass.port}",
                 max_retries: 0
               )

      assert returned_resource.attributes == resource_definition.create_response
      assert returned_resource.__struct__ == resource_definition.struct_module
    end

    test "#{inspect(resource_definition.module)}.update/3 posts the update payload" do
      resource_definition = unquote(Macro.escape(resource_definition))
      bypass = Bypass.open()
      client = client(minor_version: 75)

      Bypass.expect_once(
        bypass,
        "POST",
        "/v3/company/9130357992221046/#{resource_definition.path}",
        fn connection ->
          connection =
            assert_request(connection,
              method: :post,
              url:
                "/v3/company/9130357992221046/#{resource_definition.path}?operation=update&minorversion=75",
              headers: [{"authorization", "Bearer access-token"}],
              body: resource_definition.update_attributes
            )

          response_body =
            Jason.encode!(%{
              resource_definition.response_name => resource_definition.update_attributes
            })

          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, response_body)
        end
      )

      assert {:ok, returned_resource} =
               resource_definition.module.update(client, resource_definition.update_attributes,
                 base_url: "http://localhost:#{bypass.port}",
                 max_retries: 0
               )

      assert returned_resource.attributes == resource_definition.update_attributes
      assert returned_resource.__struct__ == resource_definition.struct_module
    end

    test "#{inspect(resource_definition.module)}.get/3 returns not_found for missing resources" do
      resource_definition = unquote(Macro.escape(resource_definition))
      bypass = Bypass.open()
      client = client()

      Bypass.expect_once(
        bypass,
        "GET",
        "/v3/company/9130357992221046/#{resource_definition.path}/404",
        fn connection ->
          connection
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(
            404,
            ~s({"Fault":{"Error":[{"Message":"Object Not Found","Detail":"Resource was not found","code":"610"}],"type":"ValidationFault"}})
          )
        end
      )

      assert {:error, %ExQuickbooks.Error{} = error} =
               resource_definition.module.get(client, "404",
                 base_url: "http://localhost:#{bypass.port}",
                 max_retries: 0
               )

      assert error.type == :not_found
      assert error.status == 404
      assert error.message == "Resource was not found"
    end
  end

  test "list/2 validates the where option type" do
    client = client()

    assert {:error, %ExQuickbooks.Error{} = error} =
             ExQuickbooks.Customers.list(client, where: 123)

    assert error.type == :validation_failed
    assert error.message =~ "where"
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
