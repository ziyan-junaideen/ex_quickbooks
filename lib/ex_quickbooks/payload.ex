defmodule ExQuickbooks.Payload do
  @moduledoc false

  @entity_modules %{
    "Account" => ExQuickbooks.Account,
    "CompanyInfo" => ExQuickbooks.CompanyInfo,
    "Customer" => ExQuickbooks.Customer,
    "Invoice" => ExQuickbooks.Invoice,
    "Item" => ExQuickbooks.Item,
    "Payment" => ExQuickbooks.Payment,
    "Vendor" => ExQuickbooks.Vendor
  }

  @spec normalize_response([String.t()] | nil, term()) :: term()
  def normalize_response(nil, payload), do: payload

  def normalize_response(["QueryResponse"], %{} = query_response) do
    Enum.into(query_response, %{}, fn {response_key, response_value} ->
      {response_key, normalize_entity_value(response_key, response_value)}
    end)
  end

  def normalize_response(["CDCResponse"], cdc_response), do: cdc_response

  def normalize_response([response_key], response_value) do
    normalize_entity_value(response_key, response_value)
  end

  def normalize_response(_response_path, payload), do: payload

  @spec normalize_entity_collection(String.t(), list()) :: list()
  def normalize_entity_collection(entity_name, entity_records) when is_list(entity_records) do
    Enum.map(entity_records, &normalize_entity_value(entity_name, &1))
  end

  @spec normalize_deleted_id(map()) :: ExQuickbooks.DeletedId.t()
  def normalize_deleted_id(%{} = deleted_id_attributes) do
    ExQuickbooks.DeletedId.new(deleted_id_attributes)
  end

  defp normalize_entity_value(entity_name, entity_value) when is_list(entity_value) do
    normalize_entity_collection(entity_name, entity_value)
  end

  defp normalize_entity_value(entity_name, %{} = entity_attributes) do
    case Map.get(@entity_modules, entity_name) do
      nil ->
        entity_attributes

      entity_module ->
        entity_module.new(entity_attributes)
    end
  end

  defp normalize_entity_value(_entity_name, entity_value), do: entity_value
end
