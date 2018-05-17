
RSpec.shared_examples 'it has scopes to get advice and managed parts' do
  ['advice', 'managed'].each do |support_type|
    let :part_type { described_class.to_s.downcase }
    context "for #{support_type} scope" do
      subject do
        create(:cluster, support_type: support_type) do |cluster|
          3.times { create(part_type.to_sym, cluster: cluster, support_type: 'inherit' ) }
          create(part_type.to_sym, cluster: cluster, support_type: 'managed')
          create(part_type.to_sym, cluster: cluster, support_type: 'advice')
        end
      end

      it "returns all components of support type #{support_type}" do
        result = subject.public_send(part_type.pluralize).public_send(support_type)
        expect(result).to all be_a(described_class)
        expect(result.length).to eq 4
      end
    end
  end
end
