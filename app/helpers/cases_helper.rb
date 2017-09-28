module CasesHelper
  def options_for_site_components
    options_for_select(site_components_array)
  end

  def options_for_case_categories
    arr = build_options_array(@case_categories) do |case_category|
      { class: "data-case-category-id-#{case_category.id}" }
    end
    options_for_select(arr)
  end

  private

  def site_components_array
    @site_components.map do |site_component|
      [
        site_component.name,
        site_component.id,
        { class: "data-component-type-id-#{site_component.component_type.id}" }
      ]
    end
  end

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
