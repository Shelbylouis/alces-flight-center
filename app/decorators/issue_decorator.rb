class IssueDecorator < ApplicationDecorator
  delegate_all
  decorates_association :tiers

  def case_form_json
    {
      id: id,
      name: name,
      defaultSubject: default_subject,
      requiresComponent: requires_component,
      supportType: support_type,
      chargeable: chargeable,
      tiers: tiers.map(&:case_form_json)
    }
  end
end
