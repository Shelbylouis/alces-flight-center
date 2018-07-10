class ComponentGroupDecorator < ClusterPartDecorator
  include AssetRecordDecorator

  delegate_all

  decorates_association :components

  def path
    h.component_group_path(self)
  end

  def link
    component_name = h.pluralize(components.length, component_type.name)
    h.link_to "#{name} — #{component_name}", path
  end

  def tabs
    [
      { id: :components, path: h.component_group_components_path(self) },
      tabs_builder.asset_record
    ]
  end

  def fa_icon
    'fa-cubes'
  end

  def type_name
    "Group of #{component_type.name.pluralize.downcase}"
  end
end
