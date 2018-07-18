
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
          {}.tap {|attrs| attrs[markdown_column] = markdown_text}
        ).send("rendered_#{markdown_column}")
      end

      let(:markdown_text) do
        <<~EOF
        # Title

        Paragraph

         - List item 1
         - List item 2

        <script>alert('I am hakz you now')</script>
        EOF
      end

      let(:html_text) do
        <<~EOF
        <div class="markdown">
        <h1 id="title">Title</h1>

        <p>Paragraph</p>

        <ul>
          <li>List item 1</li>
          <li>List item 2</li>
        </ul>
        </div>
        EOF
      end

      it "renders markdown" do
        expect(subject.rstrip).to eq(html_text.rstrip)
      end

      it "strips html tags" do
        expect(subject).not_to include("<script>")
        expect(subject).not_to include("alert")
        expect(subject).not_to include("I am hakz you now")
      end
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
