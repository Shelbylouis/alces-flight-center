
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

  def update_asset_record(raw_definition_hash)
    definition_hash = raw_definition_hash.map do |key, value|
      [key.to_s.to_sym, value]
    end.to_h
    asset_record.each do |field|
      updated_value = definition_hash[field.definition.id.to_s.to_sym]
      next if field.value == updated_value
      if field.asset == self && (updated_value.nil? || updated_value.empty?)
        # Delete an existing field
        field.destroy!
      elsif field.asset
        # When updating a field associated with the asset
        field.value = updated_value
        field.save!
      elsif updated_value
        # When updating a higher level field
        create_asset_record_field(field.definition, updated_value)
      end
    end
  end

  private

  def new_asset_record_hash
    asset_record_fields.map { |f| [f.definition.id, f] }.to_h
  end

  def parent_asset_record_hash
    asset_record_parent&.asset_record_hash || {}
  end

  def create_asset_record_field(definition, value)
    asset_record_fields.create!(
      asset_record_field_definition_id: definition.id,
      value: value
    )
  end
end
