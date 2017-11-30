class ComponentDecorator < ApplicationDecorator
  delegate_all
  decorates_association :cluster

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

  def links
    self_link = h.link_to name, path
    h.raw("#{self_link} (#{cluster.links})")
  end
end
