
module HasMaintenanceWindows
  extend ActiveSupport::Concern

  def open_maintenance_windows
    maintenance_windows.where.not(state: :ended)
  end
end
