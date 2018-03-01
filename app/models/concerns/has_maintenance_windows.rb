
module HasMaintenanceWindows
  extend ActiveSupport::Concern

  included do
    has_many :maintenance_windows
  end
end
