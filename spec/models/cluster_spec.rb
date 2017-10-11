require 'rails_helper'
require 'shared_examples/canonical_name'

RSpec.describe Cluster, type: :model do
  include_examples 'canonical_name'

  describe '#case_form_json' do
    subject do
      create(
        :cluster,
        id: 1,
        name: 'Some Cluster',
        support_type: :managed
      ).tap do |cluster|
        cluster.components = [create(:component, cluster: cluster)]
      end
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json),
        supportType: 'managed',
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

  context 'cluster document tests' do
    subject { create(:cluster, name: 'Some Cluster', site: site) }
    let :site { create(:site, name: 'The Site') }

    before :each do
      ENV['AWS_DOCUMENTS_PREFIX'] = 'test-documents'
    end

    describe '#documents_path' do
      it 'returns correct path' do
        expect(subject.documents_path).to eq 'test-documents/the-site/some-cluster'
      end
    end
  end
end
