
RSpec.shared_examples 'markdown_description' do
  describe '#rendered_description' do
    let :class_factory_identifier do
      described_class.to_s.downcase
    end

    subject do
      create(
        class_factory_identifier,
        description: '- some bullet point'
      ).rendered_description
    end

    it { is_expected.to include('<li>some bullet point</li>') }
  end
end
