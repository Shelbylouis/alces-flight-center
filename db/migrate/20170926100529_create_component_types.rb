class CreateComponentTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :component_types do |t|
      t.string :name, null: false
      t.string :description

      t.timestamps null: false
    end

    remove_column :components, :component_type, :string
    remove_column :components, :description, :string

    add_reference :components, :component_type, foreign_key: true
  end
end
