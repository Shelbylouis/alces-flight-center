class MaintenanceWindowAssociation < ApplicationRecord
  belongs_to :maintenance_window
  belongs_to :associated_element,
             polymorphic: true

  delegate :site, to: :maintenance_window

  validates :associated_element_id,
            uniqueness: {
              scope: [:associated_element_type, :maintenance_window_id],
            }
end
