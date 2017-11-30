class AddPossibleAssociationsToMaintenanceWindows < ActiveRecord::Migration[5.1]
  def change
    add_reference :maintenance_windows, :cluster, null: true
    add_reference :maintenance_windows, :component, null: true
    add_reference :maintenance_windows, :service, null: true
  end
end
