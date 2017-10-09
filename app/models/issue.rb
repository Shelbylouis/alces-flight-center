class Issue < ApplicationRecord
  belongs_to :case_category
  validates :name, presence: true

  def case_form_json
    {
      id: id,
      name: name,
      requiresComponent: requires_component,
    }
  end
end
