class MakeMaintenanceWindowFieldsNonNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :maintenance_windows, :requested_start, false
    change_column_null :maintenance_windows, :duration, false
  end
end
