
module AdminConfig::MaintenanceWindow
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :maintenance_window_state_transitions do
          hide
        end
      end
    end
  end
end
