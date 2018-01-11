
module HasAssetRecords
  extend ActiveSupport::Concern

  # Method to be called from AdminConfig to format Component asset record for
  # displaying to admins.
  def asset_record_view
    asset_record.to_json
  end

  def asset_record
    @asset_record ||=
      combined_asset_record_fields.map do |field|
        [field.name, field.value]
      end.to_h
  end

  def combined_asset_record_fields
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
    parent_for_asset_record_fields&.combined_asset_record_fields
  end
end
