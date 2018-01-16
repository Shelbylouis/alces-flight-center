require 'rails_helper'

RSpec.describe HasAssetRecord, type: :model do
  describe '#asset_record' do
    let :grand_parent do
      create_asset(
        fields: { 4 => 'grand_parent_field' }
      )
    end

    let :parent do
      create_asset(
        parent: grand_parent,
        fields: { 2 => 'parent_asset_field', 3 => 'parent_override_field' }
      )
    end

    subject do
      create_asset(
        parent: parent,
        fields: {
          1 => 'subject_asset_field',
          3 => 'subject_override_field'
        }
      )
    end

    def create_asset(parent: nil, fields: {})
      # The asset_record_fields are merged according to the Definition id
      asset_fields = fields.each_with_object([]) do |(id, msg), memo|
        asset_def = { definition: double(AssetRecordFieldDefinition, id: id) }
        memo.push(double(AssetRecordField, **asset_def, value: msg.to_s))
      end
      # Final test object which contains the fields and the parent
      OpenStruct.new(
        name: 'Component-ish',
        asset_record_fields: asset_fields,
        asset_record_parent: parent
      ).tap { |x| x.extend(HasAssetRecord) }
    end

    def asset_values(obj = subject)
      obj.asset_record.map(&:value)
    end

    it 'includes the asset_record_fields for the current layer' do
      expect(asset_values).to include('subject_asset_field')
    end

    it 'includes its parent fields' do
      expect(asset_values).to include('parent_asset_field')
    end

    it 'allows multiple chained asset records' do
      expect(asset_values).to include('grand_parent_field')
    end

    it 'subject fields override their parents' do
      expect(asset_values).to include('subject_override_field')
      expect(asset_values).not_to include('parent_override_field')
    end
  end

  describe '#update' do
    let :type_only_definition { create(:asset_record_field_definition) }
    let :component_type do
      create(
        :component_type,
        asset_record_field_definitions: [type_only_definition]
      )
    end
    let :component_make do
      create(:component_make, component_type: component_type)
    end
    let :component_group do
      create(:component_group, component_make: component_make)
    end

    subject { create(:component, component_group: component_group) }

    def definition_hash(obj)
      obj.asset_record.map { |r| [r.definition.id, r.value] }
    end

    it 'does nothing if no values have changed' do
      old_hash = definition_hash(subject)
      subject.update_asset_record(old_hash.deep_dup)
      expect(definition_hash(subject)).to eq(old_hash)
    end
  end
end
