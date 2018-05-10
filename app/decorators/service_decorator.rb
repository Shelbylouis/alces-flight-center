class ServiceDecorator < ClusterPartDecorator
  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_service_becomes_advice_issue,
      request_managed_issue: Issue.request_service_becomes_managed_issue
    )
  end

  def path
    h.service_path(self)
  end

  def tabs
    [tabs_builder.overview, tabs_builder.cases, tabs_builder.maintenance]
  end
end
