class AddNewMaintenanceWindowsStateFields < ActiveRecord::Migration[5.1]
  def change
    change_table :maintenance_windows do |t|
      t.timestamp :requested_start
      t.timestamp :requested_end
      t.timestamp :requested_at
      t.timestamp :confirmed_at
      t.timestamp :started_at
      t.timestamp :expired_at

      t.references :rejected_by,
        foreign_key: {to_table: :users },
        null: true
      t.timestamp :rejected_at

      t.references :cancelled_by,
        foreign_key: {to_table: :users },
        null: true
      t.timestamp :cancelled_at
    end
  end
end
