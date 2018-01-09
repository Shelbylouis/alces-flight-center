
module HasAssetRecordFields
  extend ActiveSupport::Concern

  # Method to be called from AdminConfig to format Component asset record for
  # displaying to admins.
  def asset_record_view
    asset_record.to_json
  end

  def asset_record
    @asset_record ||=
      asset_record_fields.map(&:value).map do |field|
        [field.name, field.value]
      end.to_h
  end

  def asset_record_fields
    hashify_asset_record_fields(parent_asset_record_fields)
      .merge(hashify_asset_record_fields(super))
      .values
  end

  private

  def hashify_asset_record_fields(records)
    (records || []).map do |field|
      [field.definition.id, field]
    end.to_h
  end
end
