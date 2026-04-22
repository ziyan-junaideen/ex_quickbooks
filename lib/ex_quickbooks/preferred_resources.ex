defmodule ExQuickBooks.Customers do
  @moduledoc """
  Customer resource helpers for QuickBooks.
  """

  @doc """
  Lists customers, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Customers.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches a customer by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Customers.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates a customer.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Customers.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates a customer.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Customers.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Items do
  @moduledoc """
  Item resource helpers for QuickBooks.
  """

  @doc """
  Lists items, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Items.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches an item by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Items.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates an item.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Items.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates an item.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Items.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Invoices do
  @moduledoc """
  Invoice resource helpers for QuickBooks.
  """

  @doc """
  Lists invoices, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Invoices.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches an invoice by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Invoices.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates an invoice.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Invoices.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates an invoice.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Invoices.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Payments do
  @moduledoc """
  Payment resource helpers for QuickBooks.
  """

  @doc """
  Lists payments, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Payments.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches a payment by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Payments.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates a payment.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Payments.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates a payment.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Payments.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Accounts do
  @moduledoc """
  Account resource helpers for QuickBooks.
  """

  @doc """
  Lists accounts, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Accounts.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches an account by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Accounts.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates an account.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Accounts.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates an account.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Accounts.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end

defmodule ExQuickBooks.Vendors do
  @moduledoc """
  Vendor resource helpers for QuickBooks.
  """

  @doc """
  Lists vendors, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickBooks.Client.t(), keyword()) ::
          {:ok, [map()]} | {:error, ExQuickBooks.Error.t()}
  def list(client, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Vendors.list(options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Fetches a vendor by ID.
  """
  @spec get(ExQuickBooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def get(client, id, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Vendors.get(id, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Creates a vendor.
  """
  @spec create(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def create(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Vendors.create(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end

  @doc """
  Updates a vendor.
  """
  @spec update(ExQuickBooks.Client.t(), map(), keyword()) ::
          {:ok, map()} | {:error, ExQuickBooks.Error.t()}
  def update(client, attributes, options \\ []) do
    client
    |> ExQuickbooks.PreferredAPI.legacy_client()
    |> ExQuickbooks.Vendors.update(attributes, options)
    |> ExQuickbooks.PreferredAPI.new_result()
  end
end
