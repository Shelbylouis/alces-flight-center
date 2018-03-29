class TrackDurationInMaintenanceTransitions < ActiveRecord::Migration[5.1]
  def change
    add_column :maintenance_window_state_transitions, :duration, :integer
  end
end
