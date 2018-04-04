class TrackRequestedStartAndEndInTransitions < ActiveRecord::Migration[5.1]
  def change
    add_column :maintenance_window_state_transitions, :requested_start, :datetime
    add_column :maintenance_window_state_transitions, :requested_end, :datetime
  end
end
