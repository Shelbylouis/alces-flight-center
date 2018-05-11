require 'rails_helper'

RSpec.describe Component, type: :model do
  include_examples 'inheritable_support_type'

  describe '#asset_record' do
    subject { create(:component) }

    let :asset_record_field_definitions do
      [
        { field_name: 'Ip', level: 'component' },
        { field_name: 'Model/manufacturer name', level: 'group' },
        { field_name: 'OS deployed', level: 'group' },
        { field_name: 'Comments', level: 'group' },
      ].map do |props|
        create(
          :asset_record_field_definition,
          field_name: props[:field_name],
          level: props[:level],
          component_types: [subject.component_type]
        )
      end
    end
    it 'returns merged array of all applicable asset record fields' do
      ip_field_definition,
        model_field_definition,
        os_field_definition = asset_record_field_definitions

      create(
        :unassociated_asset_record_field,
        component: subject,
        asset_record_field_definition: ip_field_definition,
        value: '1.2.3.4'
      )

      create(
        :unassociated_asset_record_field,
        component_group: subject.component_group,
        asset_record_field_definition: model_field_definition,
        value: 'Dell server'
      )

      # Create asset record field for this definition associated with both
      # ComponentGroup and Component within that group, to test that value set
      # at Component-level takes precedence.
      create(
        :unassociated_asset_record_field,
        component_group: subject.component_group,
        asset_record_field_definition: os_field_definition,
        value: 'CentOS 7'
      )
      create(
        :unassociated_asset_record_field,
        component: subject,
        asset_record_field_definition: os_field_definition,
        value: 'Windows o_O'
      )

      subject.reload

      field_names_to_values = subject.asset_record.map do |r|
        [r.definition.field_name, r.value]
      end.to_h
      expect(field_names_to_values).to eq(
        'Ip' => '1.2.3.4',
        'Model/manufacturer name' => 'Dell server',

        # Component-level field value should take precedence.
        'OS deployed' => 'Windows o_O',

        # Field definition included in definitions associated with
        # ComponentType, but without an AssetRecordField associated with
        # Component or ComponentGroup, should still be included.
        'Comments' => '')
    end
  end

  describe "create ComponentExpansion's from ComponentDefault's" do
    let :expansion_names { (1..2).map { |i| "expansion#{i}" } }
    let :default_expansions do
      expansion_names.map { |slot| create(:default_expansion, slot: slot) }
    end
    let :component_make do
      create(:component_make, default_expansions: default_expansions)
    end
    let :component_group do
      create(:component_group, component_make: component_make)
    end

    subject do
      component_group.components.create!(name: 'test').component_expansions
    end

    it 'creates the correct number of expansions' do
      expect(subject.length).to eq(expansion_names.length)
    end

    it 'creates the component_expansions' do
      expect(subject.map(&:slot)).to include(*expansion_names)
    end
  end
end
