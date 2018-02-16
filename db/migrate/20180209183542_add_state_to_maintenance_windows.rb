class AddStateToMaintenanceWindows < ActiveRecord::Migration[5.1]
  def change
    add_column :maintenance_windows,
      :state,
      :text,
      null: false,
      default: :requested
  end
end
