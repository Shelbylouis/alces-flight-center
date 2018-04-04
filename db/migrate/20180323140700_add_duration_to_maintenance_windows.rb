class AddDurationToMaintenanceWindows < ActiveRecord::Migration[5.1]
  def change
    add_column :maintenance_windows, :duration, :integer
  end
end
