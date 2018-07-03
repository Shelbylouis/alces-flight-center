class AddMultipleAssociationsToCases < ActiveRecord::Migration[5.2]
  def change
    create_table :case_associations do |t|
      t.references :case,
                   index: true,
                   null: false,
                   foreign_key: true
      t.references :associated_element,
                   polymorphic: true,
                   index: { name: 'index_case_associations_by_assoc_element'},
                   null: false
    end

    add_index :case_associations, [:case_id, :associated_element_id, :associated_element_type],
              name: 'index_case_associations_uniqueness',
              unique: true
  end
end
