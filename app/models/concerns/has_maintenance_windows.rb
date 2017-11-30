
module HasMaintenanceWindows
  extend ActiveSupport::Concern

  def open_maintenance_windows
    maintenance_windows.where(ended_at: nil)
  end
end
