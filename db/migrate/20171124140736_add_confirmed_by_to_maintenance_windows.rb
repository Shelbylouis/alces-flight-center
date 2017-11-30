class AddConfirmedByToMaintenanceWindows < ActiveRecord::Migration[5.1]
  def change
    add_reference :maintenance_windows,
      :confirmed_by,
      foreign_key: {to_table: :users },
      null: true
  end
end
