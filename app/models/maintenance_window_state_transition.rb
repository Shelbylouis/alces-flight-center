class MaintenanceWindowStateTransition < ApplicationRecord
  belongs_to :maintenance_window
  belongs_to :user, required: false

  delegate :site, to: :maintenance_window
end
