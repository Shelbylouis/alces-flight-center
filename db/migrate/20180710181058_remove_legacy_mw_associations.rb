class RemoveLegacyMwAssociations < ActiveRecord::Migration[5.2]
  def change
    remove_index :maintenance_windows, :cluster_id
    remove_index :maintenance_windows, :component_id
    remove_index :maintenance_windows, :service_id

    remove_column :maintenance_windows, :cluster_id, :integer
    remove_column :maintenance_windows, :component_id, :integer
    remove_column :maintenance_windows, :service_id, :integer
  end
end
