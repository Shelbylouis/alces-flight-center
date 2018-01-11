
module HasAssetRecord
  extend ActiveSupport::Concern

  # Method to be called from AdminConfig to format Component asset record for
  # displaying to admins.
  def asset_record_view
    asset_records.map do |field|
      [field.name, field.value]
    end.to_h.to_json
  end

  def asset_records
    hashify_asset_record_fields(parent_asset_record_fields)
      .merge(hashify_asset_record_fields(asset_record_fields))
      .values
  end

  private

  def hashify_asset_record_fields(records)
    (records || []).map do |field|
      [field.definition.id, field]
    end.to_h
  end

  def parent_asset_record_fields
    asset_record_parent&.asset_records
  end
end
