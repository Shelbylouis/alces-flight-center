require 'rails_helper'

RSpec.describe HasAssetRecord, type: :model do
  context 'with a double standard for the subject' do
    let :overriden_index { 255 }

    let :grand_parent do
      create_asset(
        fields: { 4 => 'grand_parent_field' }
      )
    end

    let :parent do
      create_asset(
        parent: grand_parent,
        fields: {
          2 => 'parent_asset_field',
          overriden_index => 'parent_override_field'
        }
      )
    end

    subject do
      create_asset(
        parent: parent,
        fields: {
          1 => 'subject_asset_field',
          overriden_index => 'subject_override_field'
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

    describe '#asset_record' do
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

    describe '#find_parent_asset_record' do
      it 'finds the parents record' do
        expected_parent_record = parent.asset_record_hash[overriden_index]
        overriden_def = subject.asset_record_hash[overriden_index].definition
        found_record = subject.find_parent_asset_record overriden_def
        expect(found_record).to eq(expected_parent_record)
      end
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

    let! :set_definition do
      create(
        :asset_record_field_definition,
        component_types: [subject.component_type]
      ).tap do |definition|
        create(
          :unassociated_asset_record_field,
          definition: definition,
          component: subject,
          value: 'initial value'
        )
        subject.reload
      end
    end

    let! :group_definition do
      create(
        :asset_record_field_definition,
        component_types: [subject.component_type]
      ).tap do |definition|
        create(
          :unassociated_asset_record_field,
          definition: definition,
          component_group: subject.component_group,
          value: 'group'
        )
        subject.reload
        subject.component_group.reload
      end
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

    # The comparison is done using inspect/ string comparison
    # This prevents issues with the tests sneakily changing the old_fields
    # making it hard to tell if it has changed
    # WARNING!! It can not be used to test deleted fields
    def changed_fields
      old_fields = subject.asset_record_fields.to_ary.map(&:inspect)
      yield if block_given?
      subject.reload.asset_record_fields.to_ary.delete_if do |field|
        old_fields.include?(field.inspect)
      end
    end

    it 'does nothing if no values have changed' do
      subject.update_asset_record(old_hash.deep_dup)
      expect(definition_hash(subject)).to eq(old_hash)
    end

    it 'creates a new field when component_type definition is updated' do
      new_fields = changed_fields do
        subject.update_asset_record(
          old_hash.merge(type_only_definition.id => 'component')
        )
      end
      expect(new_fields.length).to eq(1)
      expect_update(type_only_definition, new_fields.first, 'component')
    end

    it "doesn't create a new component_type field with an empty value" do
      new_fields = changed_fields do
        subject.update_asset_record(
          old_hash.merge(type_only_definition.id => '')
        )
      end
      expect(new_fields.length).to eq(0)
    end

    it 'can update an existing record for the component' do
      updated_fields = changed_fields do
        subject.update_asset_record(
          old_hash.merge(set_definition.id => 'component')
        )
      end
      expect(updated_fields.length).to eq(1)
      expect_update(set_definition, updated_fields.first, 'component')
    end

    it 'does not update the higher level record' do
      subject.update_asset_record(
        old_hash.merge(group_definition.id => 'component')
      )
      subject.reload
      subject.component_group.reload

      group_record = subject.component_group.asset_record.find do |record|
        record.definition == group_definition
      end

      expect(group_record.value).to eq('group')
    end

    it 'does not replace higher level assets with a blank field' do
      updated_fields = changed_fields do
        subject.update_asset_record(
          old_hash.merge(group_definition.id => '')
        )
      end
      expect(updated_fields.length).to eq(0)
    end

    shared_examples 'delete asset field' do |input|
      it "deletes the record when it is updated to: #{input.inspect}" do
        delete_field = subject.asset_record_fields.first
        subject.update_asset_record(
          old_hash.merge(delete_field.definition.id => input)
        )
        subject.reload
        expect(subject.asset_record_fields).not_to include(delete_field)
      end
    end

    include_examples 'delete asset field', nil
    include_examples 'delete asset field', ''
  end
end
