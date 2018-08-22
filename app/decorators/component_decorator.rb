class ComponentDecorator < ClusterPartDecorator

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_component_becomes_advice_issue,
      request_managed_issue: Issue.request_component_becomes_managed_issue
    )
  end

  def path
    h.component_path(self)
  end

  def tabs
    [
      tabs_builder.overview,
      tabs_builder.logs,
      tabs_builder.maintenance,
      tabs_builder.read_only_cases,
    ]
  end

  def link
    h.link_to self.name, path
  end

  def fa_icon
    'fa-cube'
  end

  def type_name
    model.component_type
  end
end
