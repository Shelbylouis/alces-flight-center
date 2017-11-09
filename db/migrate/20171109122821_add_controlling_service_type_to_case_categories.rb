class AddControllingServiceTypeToCaseCategories < ActiveRecord::Migration[5.1]
  def change
    add_reference :case_categories,
      :controlling_service_type,
      foreign_key: {to_table: :service_types},
      null: true
  end
end
