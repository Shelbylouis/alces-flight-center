class ComponentGroupDecorator < ClusterPartDecorator

  delegate_all

  decorates_association :components

  def path
    h.component_group_path(self)
  end

  def link
    h.link_to "#{name} (#{components.length})", path
  end

  def tabs
    [
      { id: :components, path: h.component_group_components_path(self) },
      tabs_builder.read_only_cases,
      tabs_builder.cluster_composition(h),
    ]
  end

  def fa_icon
    'fa-cubes'
  end

  def type_name
    'Group'
  end
end
