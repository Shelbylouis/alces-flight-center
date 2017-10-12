require 'rails_helper'

RSpec.describe Component, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :component,
        id: 1,
        name: 'Some Component',
        cluster: create(:cluster, id: 2),
        support_type: :managed,
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Some Component',
        supportType: 'managed',
      })
    end
  end

  describe '#support_type' do
    let :cluster { create(:cluster, support_type: 'advice') }

    it "returns cluster.support_type when set to 'inherit'" do
      component = create(:component, support_type: 'inherit', cluster: cluster)

      expect(component.support_type).to eq('advice')
    end

    it "returns own support_type otherwise" do
      component = create(:component, support_type: 'managed', cluster: cluster)

      expect(component.support_type).to eq('managed')
    end
  end

  describe '#asset_record' do
    subject { create(:component) }

    let :asset_record_field_definitions do
      [
        { field_name: 'Ip', level: 'component' },
        { field_name: 'Model/manufacturer name', level: 'group' },
        { field_name: 'OS deployed', level: 'group' },
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

      expect(subject.asset_record).to eq({
        'Ip' => '1.2.3.4',
        'Model/manufacturer name' => 'Dell server',
        'OS deployed' => 'Windows o_O',
      })
    end
  end
end
