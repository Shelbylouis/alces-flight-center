class RemoveObsoleteComponentModels < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :asset_record_field_definitions_component_types, :asset_record_field_definitions
    remove_foreign_key :asset_record_field_definitions_component_types, :component_types
    remove_foreign_key :asset_record_fields, :asset_record_field_definitions
    remove_foreign_key :asset_record_fields, :component_groups
    remove_foreign_key :asset_record_fields, :components
    remove_foreign_key :component_groups, :component_makes
    remove_foreign_key :component_makes, :component_types
    remove_foreign_key :expansions, :component_makes
    remove_foreign_key :expansions, :components
    remove_foreign_key :expansions, :expansion_types

    drop_table :asset_record_field_definitions
    drop_table :asset_record_fields
    drop_table :component_makes
    drop_table :component_types
    drop_table :expansions
    drop_table :expansion_types

    remove_column :component_groups, :component_make_id
  end
end
