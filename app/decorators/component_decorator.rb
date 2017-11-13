class ComponentDecorator < ApplicationDecorator
  delegate_all

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_component_becomes_advice_issue,
      request_managed_issue: Issue.request_component_becomes_managed_issue,
      part_id_symbol: :component_id
    )
  end

  def path
    h.component_path(self)
  end
end