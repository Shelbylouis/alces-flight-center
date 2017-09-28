module CasesHelper
  def options_for_site_components
    build_options_with_data_attributes(@site_components) do |site_component|
      { 'component-type': site_component.component_type.id }
    end
  end

  def options_for_case_categories
    build_options_with_data_attributes(@case_categories) do |case_category|
      component_id = case_category.component_type&.id
      component_id ? { 'component-type': component_id } : {}
    end
  end

  private

  ##
  # The hash returned from the block becomes the html attributes hash
  def build_options_with_data_attributes(object_array)
    arr = object_array.map do |obj|
      [
        obj.name,
        obj.id,
        convert_keys_to_data_id_tag(yield(obj))
      ]
    end
    options_for_select(arr)
  end

  def convert_keys_to_data_id_tag(data_hash = {})
    data_hash.inject({}) do |memo, (key, value)|
      memo["data-#{key}-id"] = value
      memo
    end
  end
end
