class CaseCategory < ApplicationRecord
  belongs_to :component_type, required: false

  validates :name, presence: true

  def case_form_json
    {
      id: id,
      name: name,
      requiresComponent: requires_component
    }
  end
end
