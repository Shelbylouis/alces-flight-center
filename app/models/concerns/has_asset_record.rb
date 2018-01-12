
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
    new_asset_ids = asset_record_fields.map { |m| m.definition.id }
    parent_asset_records.inject(asset_record_fields) do |memo, r|
      memo << r unless new_asset_ids.include? r.definition.id
      memo
    end
  end

  private

  def parent_asset_records
    asset_record_parent&.asset_records || []
  end
end
