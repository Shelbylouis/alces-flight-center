
module HasAssetRecordFields
  extend ActiveSupport::Concern

  def asset_record_fields
    hashify_asset_record_fields(parent_asset_record_fields)
      .merge(hashify_asset_record_fields(super))
      .values
  end

  def hashify_asset_record_fields(records)
    (records || []).map do |field|
      [field.definition.id, field]
    end.to_h
  end

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

  # TODO: Remove this
  def extract_asset_record_fields(model)
    model.asset_record_fields.map do |field|
      [field.definition.id, field]
    end.to_h
  end
end
