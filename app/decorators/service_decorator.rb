class ServiceDecorator < ApplicationDecorator
  delegate_all
  decorates_association :cluster

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

  def links
    # XXX identical to `ComponentDecorator#links` .
    self_link = h.link_to name, path
    h.raw("#{self_link} (#{cluster.links})")
  end
end
