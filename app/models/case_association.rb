class CaseAssociation < ApplicationRecord
  belongs_to :case
  belongs_to :associated_element,
             polymorphic: true

  delegate :site, to: :case

  validates :associated_element_id,
            uniqueness: {
              scope: [:associated_element_type, :case_id],
            }

  audited associated_with: :case
end
