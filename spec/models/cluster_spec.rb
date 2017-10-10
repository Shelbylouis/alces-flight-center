require 'rails_helper'

RSpec.describe Cluster, type: :model do
  describe '#case_form_json' do
    subject do
      create(:cluster, id: 1, name: 'Some Cluster').tap do |cluster|
        cluster.components = [create(:component, cluster: cluster)]
      end
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json)
      })
    end
  end

  describe '#managed_components' do
    subject do
      create(:cluster, support_type: 'managed') do |cluster|
        3.times { create(:component, cluster: cluster, support_type: 'inherit') }
        create(:component, cluster: cluster, support_type: 'managed')
        create(:component, cluster: cluster, support_type: 'advice')
      end
    end

    it 'returns all managed cluster components for cluster' do
      result = subject.managed_components
      expect(result).to all be_a(Component)
      expect(result.length).to be 4
    end
  end

  describe '#advice_components' do
    subject do
      create(:cluster, support_type: 'advice') do |cluster|
        4.times { create(:component, cluster: cluster, support_type: 'inherit') }
        create(:component, cluster: cluster, support_type: 'managed')
        create(:component, cluster: cluster, support_type: 'advice')
      end
    end

    it 'returns all advice cluster components for cluster' do
      result = subject.advice_components
      expect(result).to all be_a(Component)
      expect(result.length).to be 5
    end
  end
end
