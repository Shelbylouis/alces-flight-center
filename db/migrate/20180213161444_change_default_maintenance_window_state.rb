class ChangeDefaultMaintenanceWindowState < ActiveRecord::Migration[5.1]
  def change
    change_column_default :maintenance_windows,
      :state,
      from: 'requested',
      to: 'new'
  end
end
