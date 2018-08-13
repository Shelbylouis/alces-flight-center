class SupportMultipleAssociationsToMaintenanceWindows < ActiveRecord::Migration[5.2]
  def change
    create_table :maintenance_window_associations do |t|
      t.references :maintenance_window,
                   index: true,
                   null: false,
                   foreign_key: true
      t.references :associated_element,
                   polymorphic: true,
                   index: { name: 'index_mw_associations_by_assoc_element'},
                   null: false
    end

    add_index :maintenance_window_associations, [:maintenance_window_id, :associated_element_id, :associated_element_type],
              name: 'index_mw_associations_uniqueness',
              unique: true
  end
end
