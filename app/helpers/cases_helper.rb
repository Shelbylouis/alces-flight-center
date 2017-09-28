module CasesHelper
  def options_for_site_components
    options_for_select(site_components_array)
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
end
