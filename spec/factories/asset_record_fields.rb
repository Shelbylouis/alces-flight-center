FactoryBot.define do
  factory :component_record, class: AssetRecordField do
    definition
    component
    value 'default-factory-value'

    # Link the ComponentType to the Definition so it remains valid
    after :build do |record|
      type = record.component.component_type
      record.definition.tap do |definition|
        return if definition.component_types.include? type
        definition.component_types.push type
        definition.save!
      end
    end
  end

  factory :unassociated_asset_record_field, class: AssetRecordField do
    asset_record_field_definition
    value ''
  end
end
