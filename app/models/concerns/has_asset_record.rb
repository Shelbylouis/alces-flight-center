
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

  def find_parent_asset_record(definition)
    parent_asset_record_hash[definition.id]
  end

  def asset_record_hash
    parent_asset_record_hash.merge new_asset_record_hash
  end

  def update_asset_record(raw_definition_hash)
    definition_hash = raw_definition_hash.map do |key, value|
      [key.to_s.to_sym, value]
    end.to_h
    asset_record.map do |field|
      updated_value = definition_hash[field.definition.id.to_s.to_sym]
      if updated_value.nil?
        # A nil likely means the definition was not submitted in the form
        # In this case, the record shouldn't be deleted as a form error could
        # trigger db entries to be deleted
        nil
      elsif updated_value.empty?
        # Explicitly delete the entry if an empty string is received and the
        # record belongs to the current asset, otherwise do nothing
        field.destroy! if field.asset == self
        nil
      elsif field.asset == self
        # When updating a field associated with the asset
        field.value = updated_value
        field.save
      else
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
    asset_record_fields.create(
      asset_record_field_definition_id: definition.id,
      value: value
    )
  end
end
