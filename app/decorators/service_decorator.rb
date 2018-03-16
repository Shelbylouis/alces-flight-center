class ServiceDecorator < ClusterPartDecorator
  alias :case_form_buttons :cluster_part_case_form_buttons

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_service_becomes_advice_issue,
      request_managed_issue: Issue.request_service_becomes_managed_issue,
      part_id_symbol: :service_id
    )
  end

  def path
    h.service_path(self)
  end

  def tabs
    [tabs_builder.overview, tabs_builder.cases]
  end
end
