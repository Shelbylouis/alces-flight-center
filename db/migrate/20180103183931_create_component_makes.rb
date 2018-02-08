class CreateComponentMakes < ActiveRecord::Migration[5.1]
  def change
    create_table :component_makes do |t|
      t.string :manufacturer, null: false
      t.string :model, null: false
      t.string :knowledgebase_url, null: false
      t.references :component_type, foreign_key: true, null: false
    end

    add_reference :component_groups, :component_make, foreign_key: true, null: true
    remove_reference :component_groups, :component_type
  end
end
