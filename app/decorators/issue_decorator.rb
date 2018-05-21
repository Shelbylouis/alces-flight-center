class IssueDecorator < ApplicationDecorator
  delegate_all
  decorates_association :tiers
  decorates_association :category

  def case_form_json
    {
      id: id,
      name: name,
      defaultSubject: default_subject,
      requiresComponent: requires_component,
      chargeable: chargeable,
      tiers: tiers.map(&:case_form_json)
    }
  end
end
