
RSpec.shared_examples 'inheritable_support_type' do
  let :class_factory_identifier do
    SpecUtils.class_factory_identifier(described_class)
  end

  describe '#support_type' do
    let :cluster { create(:cluster, support_type: 'advice') }

    it "returns cluster.support_type when set to 'inherit'" do
      instance = create(
        class_factory_identifier,
        support_type: 'inherit',
        cluster: cluster
      )

      expect(instance.support_type).to eq('advice')
    end

    it 'returns own support_type otherwise' do
      instance = create(
        class_factory_identifier,
        support_type: 'managed',
        cluster: cluster
      )

      expect(instance.support_type).to eq('managed')
    end
  end
end
