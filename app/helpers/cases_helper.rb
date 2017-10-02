module CasesHelper
  def options_for_site_components
    arr = build_options_array(@site_components) do |site_component|
      { "data-component-type-id": site_component.component_type.id }
    end
    options_for_select(arr)
  end

  def options_for_case_categories
    arr = build_options_array(@case_categories) do |case_category|
      component_id = case_category.component_type&.id
      component_id ? { 'data-component-type-id': component_id } : {}
    end
    options_for_select(arr)
  end

  private

  ##
  # The hash returned from the block becomes the html attributes hash
  def build_options_array(object_array)
    object_array.map do |obj|
      [
        obj.name,
        obj.id,
        yield(obj)
      ]
    end
  end
end
