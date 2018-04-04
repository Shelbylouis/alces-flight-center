class RemoveMaintenanceWindowRequestedEnd < ActiveRecord::Migration[5.1]
  def change
    [:maintenance_windows, :maintenance_window_state_transitions].each do |table|
      remove_column table, :requested_end, :timestamp
    end
  end
end
