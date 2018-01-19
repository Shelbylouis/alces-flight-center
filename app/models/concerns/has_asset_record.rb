
module HasAssetRecord
  extend ActiveSupport::Concern

  # Method to be called from AdminConfig to format Component asset record for
  # displaying to admins.
  def asset_record_view
    asset_record.map do |field|
      [field.name, field.value]
    end.to_h.to_json
  end

  def asset_record
    asset_record_hash.values
  end

  def asset_record_hash
    parent_asset_record_hash.merge new_asset_record_hash
  end

  private

  def new_asset_record_hash
    asset_record_fields.map { |f| [f.definition.id, f] }.to_h
  end

  def parent_asset_record_hash
    asset_record_parent&.asset_record_hash || {}
  end
end
