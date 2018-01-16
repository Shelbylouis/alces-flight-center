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
    subject { create(:component) }

    let! :type_only_definition do
      create(
        :asset_record_field_definition,
        component_types: [subject.component_type]
      )
    end

    let! :frozen_old_hash { definition_hash(subject).freeze }

    def old_hash
      frozen_old_hash.deep_dup
    end

    def definition_hash(obj)
      obj.asset_record.map { |r| [r.definition.id, r.value] }.to_h
    end

    def expect_update(definition, updated_field, new_value)
      expect(updated_field.definition).to eq(definition)
      expect(updated_field.value).to eq(new_value)
    end

    it 'does nothing if no values have changed' do
      subject.update_asset_record(old_hash.deep_dup)
      expect(definition_hash(subject)).to eq(old_hash)
    end

    it 'creates a new field when component_type definition is updated' do
      old_fields = subject.asset_record_fields.to_ary
      subject.update_asset_record(
        old_hash.merge(type_only_definition.id => 'component')
      )
      new_fields = subject.reload.asset_record_fields - old_fields
      expect(new_fields.length).to eq(1)
      expect_update(type_only_definition, new_fields.first, 'component')
    end

    it "doesn't create a new component_type field with an empty value" do
      old_fields = subject.asset_record_fields.to_ary
      subject.update_asset_record(
        old_hash.merge(type_only_definition.id => '')
      )
      new_fields = subject.reload.asset_record_fields - old_fields
      expect(new_fields.length).to eq(0)
    end
  end
end
