
RSpec.shared_examples 'it belongs to Cluster' do
  describe '#namespaced_name' do
    subject do
      factory = SpecUtils.class_factory_identifier(described_class)
      create(factory, name: 'model_name', cluster: cluster)
    end

    let :cluster do
      create(:cluster, name: 'cluster_name')
    end

    it 'returns its name along with its Cluster name' do
      expect(subject.namespaced_name).to eq(
        "model_name (cluster_name)"
      )
    end
  end
end
