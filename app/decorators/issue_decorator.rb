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
      tiers: tiers.map(&:case_form_json)
    }
  end

  def label_text
    "#{category_text}#{name}"
  end

  private

  def category_text
    if category.present?
      "#{category.name} : "
    end
  end
end
