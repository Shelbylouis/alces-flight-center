
RSpec.shared_examples 'inheritable_support_type' do
  describe '#support_type' do
    let :cluster { create(:cluster, support_type: 'advice') }

    it "returns cluster.support_type when set to 'inherit'" do
      component = create(:component, support_type: 'inherit', cluster: cluster)

      expect(component.support_type).to eq('advice')
    end

    it 'returns own support_type otherwise' do
      component = create(:component, support_type: 'managed', cluster: cluster)

      expect(component.support_type).to eq('managed')
    end
  end
end
