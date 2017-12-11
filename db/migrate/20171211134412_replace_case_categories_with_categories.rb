class ReplaceCaseCategoriesWithCategories < ActiveRecord::Migration[5.1]
  def change
    remove_reference :issues, :case_category
    remove_column :case_categories, :controlling_service_type_id, :int
    rename_table :case_categories, :categories
    add_reference :issues, :category, null: true
  end
end
