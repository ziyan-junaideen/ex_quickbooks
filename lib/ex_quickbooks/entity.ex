defmodule ExQuickbooks.Entity do
  @moduledoc false

  @spec build(module(), map(), keyword()) :: struct()
  def build(module_name, attributes, field_mappings) when is_map(attributes) do
    struct_attributes =
      Enum.reduce(field_mappings, %{attributes: attributes}, fn {field_name, source_key},
                                                                struct_attributes ->
        Map.put(struct_attributes, field_name, Map.get(attributes, source_key))
      end)

    struct(module_name, struct_attributes)
  end
end
