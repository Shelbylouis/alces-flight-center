class ComponentDecorator < ClusterPartDecorator
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

  def case_form_buttons
    buttons = [
      case_form_button(h.new_component_case_path(component_id: self.id), disabled: advice?),
      consultancy_form_button(h.new_component_consultancy_path(component_id: self.id))
    ].join
    h.raw(buttons)
  end
end
