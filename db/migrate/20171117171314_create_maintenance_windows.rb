class CreateMaintenanceWindows < ActiveRecord::Migration[5.1]
  def change
    create_table :maintenance_windows do |t|
      t.timestamps null: false

      t.timestamp :ended_at
      t.references :user, null: false
      t.references :case, null: false
    end
  end
end
