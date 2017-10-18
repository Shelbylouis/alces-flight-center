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
end
