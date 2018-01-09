
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
end
