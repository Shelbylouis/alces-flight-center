class ServiceDecorator < ClusterPartDecorator
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

  def case_form_buttons
    buttons = [
      case_form_button(h.new_service_case_path(service_id: self.id), disabled: advice?),
      consultancy_form_button(h.new_service_consultancy_path(service_id: self.id))
    ].join
    h.raw(buttons)
  end
end
