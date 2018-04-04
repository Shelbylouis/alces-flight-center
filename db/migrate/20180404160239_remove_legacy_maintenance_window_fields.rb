class RemoveLegacyMaintenanceWindowFields < ActiveRecord::Migration[5.1]
  def change
    remove_column :maintenance_windows, :ended_at_legacy, :timestamp
    remove_column :maintenance_windows, :requested_by_id_legacy, :bigint
    remove_column :maintenance_windows, :confirmed_by_id_legacy, :bigint
  end
end
