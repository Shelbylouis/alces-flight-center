
RSpec.shared_examples 'it belongs to Cluster' do
  describe '#namespaced_name' do
    subject do
      factory = SpecUtils.class_factory_identifier(described_class)
      build(factory, name: 'model_name', cluster: cluster)
    end

    let :cluster do
      create(:cluster, name: 'cluster_name')
    end

    it 'returns its name along with its Cluster name' do
      expect(subject.namespaced_name).to eq(
        "model_name (cluster_name)"
      )
    end

    context 'when cluster is nil' do
      let(:cluster) { nil }

      it 'just gives name' do
        expect(subject.namespaced_name).to eq(subject.name)
      end
    end
  end
end
