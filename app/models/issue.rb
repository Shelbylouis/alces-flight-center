class Issue < ApplicationRecord
  belongs_to :case_category
  validates :name, presence: true
  validates :details_template, presence: true

  def case_form_json
    {
      id: id,
      name: name,
      detailsTemplate: details_template,
      requiresComponent: requires_component,
    }
  end
end
