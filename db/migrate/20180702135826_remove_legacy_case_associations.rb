class RemoveLegacyCaseAssociations < ActiveRecord::Migration[5.2]
  def change
    remove_index :cases, :component_id
    remove_index :cases, :service_id

    remove_column :cases, :component_id, :integer
    remove_column :cases, :service_id, :integer
  end
end
