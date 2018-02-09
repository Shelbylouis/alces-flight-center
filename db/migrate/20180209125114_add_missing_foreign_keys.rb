class AddMissingForeignKeys < ActiveRecord::Migration[5.1]
  def change
    # The following missing foreign keys were all found using `rake
    # active_record_doctor:missing_foreign_keys`.

    add_foreign_key :additional_contacts, :sites

    add_foreign_key :asset_record_field_definitions_component_types, :asset_record_field_definitions
    add_foreign_key :asset_record_field_definitions_component_types, :component_types

    add_foreign_key :asset_record_fields, :asset_record_field_definitions
    add_foreign_key :asset_record_fields, :component_groups
    add_foreign_key :asset_record_fields, :components

    add_foreign_key :cases, :clusters
    add_foreign_key :cases, :components
    add_foreign_key :cases, :issues
    add_foreign_key :cases, :users

    add_foreign_key :clusters, :sites

    add_foreign_key :component_groups, :clusters

    add_foreign_key :components, :component_groups

    add_foreign_key :issues, :categories

    add_foreign_key :maintenance_windows, :cases
    add_foreign_key :maintenance_windows, :clusters
    add_foreign_key :maintenance_windows, :components
    add_foreign_key :maintenance_windows, :services
    add_foreign_key :maintenance_windows, :users

    add_foreign_key :users, :sites
  end
end
