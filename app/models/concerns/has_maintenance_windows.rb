
module HasMaintenanceWindows
  extend ActiveSupport::Concern

  included do
    has_many :maintenance_windows
  end

  def unfinished_maintenance_windows
    maintenance_windows.where.not(state: MaintenanceWindow.finished_states)
  end
end
