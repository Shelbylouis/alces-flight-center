class RenameMaintenanceWindowRequestedByUser < ActiveRecord::Migration[5.1]
  def change
    rename_column :maintenance_windows, :user_id, :requested_by_id
  end
end
