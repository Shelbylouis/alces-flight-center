class ServiceDecorator < ApplicationDecorator
  delegate_all

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_service_becomes_advice_issue,
      request_managed_issue: Issue.request_service_becomes_managed_issue,
      part_id_symbol: :service_id
    )
  end
end
