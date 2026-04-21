defmodule ExQuickbooks.Payments do
  @moduledoc """
  Payment resource helpers for QuickBooks.
  """

  @resource_name "Payment"
  @resource_path "payment"

  @doc """
  Lists payments, optionally filtered with a `WHERE` clause and query pagination.
  """
  @spec list(ExQuickbooks.Client.t(), keyword()) ::
          {:ok, [ExQuickbooks.Payment.t()]} | {:error, ExQuickbooks.Error.t()}
  def list(client, options \\ []) do
    ExQuickbooks.Resource.list(client, @resource_name, options)
  end

  @doc """
  Fetches a payment by ID.
  """
  @spec get(ExQuickbooks.Client.t(), String.t() | integer(), keyword()) ::
          {:ok, ExQuickbooks.Payment.t()} | {:error, ExQuickbooks.Error.t()}
  def get(client, id, options \\ []) do
    ExQuickbooks.Resource.get(client, @resource_path, @resource_name, id, options)
  end

  @doc """
  Creates a payment.
  """
  @spec create(ExQuickbooks.Client.t(), map(), keyword()) ::
          {:ok, ExQuickbooks.Payment.t()} | {:error, ExQuickbooks.Error.t()}
  def create(client, attributes, options \\ []) do
    ExQuickbooks.Resource.create(client, @resource_path, @resource_name, attributes, options)
  end

  @doc """
  Updates a payment.
  """
  @spec update(ExQuickbooks.Client.t(), map(), keyword()) ::
          {:ok, ExQuickbooks.Payment.t()} | {:error, ExQuickbooks.Error.t()}
  def update(client, attributes, options \\ []) do
    ExQuickbooks.Resource.update(client, @resource_path, @resource_name, attributes, options)
  end
end
