class CreateCaseCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :case_categories do |t|
      t.string :name, null: false
      t.string :description
      t.boolean :requires_component, null: false

      t.timestamps null: false
    end

    add_reference :case_categories, :component_type, foreign_key: true, null: true
  end
end
