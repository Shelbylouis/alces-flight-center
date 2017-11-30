require 'rails_helper'

RSpec.describe Component, type: :model do
  include_examples 'editable_asset_record_fields'
  include_examples 'inheritable_support_type'
  include_examples 'maintenance_windows'

  describe '#case_form_json' do
    subject do
      create(
        :component,
        id: 1,
        name: 'Some Component',
        support_type: :managed
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Component',
        supportType: 'managed'
      )
    end
  end

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

    it 'returns hash of asset record field names to values' do
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

      expect(subject.asset_record).to eq('Ip' => '1.2.3.4',
                                         'Model/manufacturer name' => 'Dell server',

                                         # Component-level field value should take precedence.
                                         'OS deployed' => 'Windows o_O',

                                         # Field definition included in definitions associated with
                                         # ComponentType, but without an AssetRecordField associated with
                                         # Component or ComponentGroup, should still be included.
                                         'Comments' => '')
    end
  end
end
