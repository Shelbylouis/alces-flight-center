class ComponentGroupDecorator < ClusterPartDecorator

  delegate_all

  decorates_association :components

  def path
    h.component_group_path(self)
  end

  def link
    component_name = h.pluralize(components.length, component_type)
    h.link_to "#{name} — #{component_name}", path
  end

  def tabs
    [
      { id: :components, path: h.component_group_components_path(self) },
      tabs_builder.asset_record,
      tabs_builder.read_only_cases
    ]
  end

  def fa_icon
    'fa-cubes'
  end

  def type_name
    "Group of #{component_type.pluralize.downcase}"
  end
end
