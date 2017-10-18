class CreateComponentGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :component_groups do |t|
      t.string :name, null: false
      t.references :cluster, foreign_key: true, null: false
      t.references :component_type, foreign_key: true, null: false

      t.timestamps
    end

    remove_column :components, :cluster, :integer
    remove_reference :components, :cluster
    remove_reference :components, :component_type
    add_reference :components, :component_group, foreign_key: true
  end
end
