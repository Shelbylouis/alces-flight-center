
RSpec.shared_examples 'markdown_column' do |options={}|
  markdown_column = options.fetch(:column, :description)
  test_nil = options.fetch(:test_nil, :true)

  describe "#rendered_#{markdown_column}" do
    let :class_factory_identifier do
      SpecUtils.class_factory_identifier(described_class)
    end

    context "when object has #{markdown_column}" do
      subject do
        create(
          class_factory_identifier,
          {}.tap {|attrs| attrs[markdown_column] = '- some bullet point' }
        ).send("rendered_#{markdown_column}")
      end

      it { is_expected.to include('<li>some bullet point</li>') }
    end

    if test_nil
      context "when object #{markdown_column} is nil" do
        subject do
          create(
            class_factory_identifier,
            {}.tap {|attrs| attrs[markdown_column] = nil}
          ).send("rendered_#{markdown_column}").strip
        end

        it { is_expected.to eq '' }
      end
    end
  end
end
