module CasesHelper
  def options_for_site_components
    build_options_with_data_attributes(@site_components) do |site_component|
      { "data-component-type-id": site_component.component_type.id }
    end
  end

  def options_for_case_categories
    build_options_with_data_attributes(@case_categories) do |case_category|
      component_id = case_category.component_type&.id
      component_id ? { 'data-component-type-id': component_id } : {}
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
        yield(obj)
      ]
    end
    options_for_select(arr)
  end
end
