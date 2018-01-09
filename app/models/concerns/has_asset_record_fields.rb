
module HasAssetRecordFields
  extend ActiveSupport::Concern

  def asset_record_layers
    # Each entry is a hash of definition ID to asset record field.
    [
      empty_asset_record_fields,
      group_asset_record_fields,
    ]
  end

  def group_asset_record_fields
    extract_asset_record_fields(self)
  end

  def extract_asset_record_fields(model)
    model.asset_record_fields.map do |field|
      [field.definition.id, field]
    end.to_h
  end
end
