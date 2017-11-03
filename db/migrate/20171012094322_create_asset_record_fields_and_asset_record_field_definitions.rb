class CreateAssetRecordFieldsAndAssetRecordFieldDefinitions < ActiveRecord::Migration[5.1]
  def change
    create_table :asset_record_field_definitions do |t|
      t.string :field_name, null: false
      t.string :level, null: false

      t.timestamps null: false
    end

    create_join_table(:asset_record_field_definitions, :component_types, null: false) do |t|
      # Override default names as these go over index name limit (62
      # characters).
      t.index :asset_record_field_definition_id,
              name: 'index_arfd_ct_on_asset_record_field_definition_id'
      t.index :component_type_id,
              name: 'index_arfd_ct_on_component_type_id'
    end

    create_table :asset_record_fields do |t|
      t.string :value, null: false
      t.references :component, null: true
      t.references :component_group, null: true
      t.references :asset_record_field_definition

      t.timestamps null: false
    end
  end
end
