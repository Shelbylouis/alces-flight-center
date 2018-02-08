class AddDataTypeToAssetRecordFieldDefinitions < ActiveRecord::Migration[5.1]
  def change
    add_column :asset_record_field_definitions, :data_type, :string
  end
end
