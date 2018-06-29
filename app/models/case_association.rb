class CaseAssociation < ApplicationRecord
  belongs_to :case
  belongs_to :associated_element,
             polymorphic: true

  validates :associated_element_id,
            uniqueness: {
              scope: [:associated_element_type, :case_id],
            }
end
