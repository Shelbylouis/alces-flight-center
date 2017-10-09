class CreateIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :issues do |t|
      t.string :name, null: false
      t.boolean :requires_component, null: false, default: false
      t.references :case_category, foreign_key: true, null: false

      t.timestamps null: false
    end

    remove_column :case_categories, :requires_component, :boolean
    remove_reference :case_categories, :component_type

    remove_reference :cases, :case_category
    add_reference :cases, :issue, foreign_key: true
  end
end
