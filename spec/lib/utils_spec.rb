
require 'utils'

RSpec.describe Utils do
  describe '#rt_format' do
    it 'appropriately formats a hash as text' do
      expect(
        described_class.rt_format({
          foo: 'bar',
          multiline_string: <<-EOF.strip_heredoc,
          is
          appropriately
          indented
          EOF
          another_key: 'value'
        })
      ).to eq(
        <<-EOF.strip_heredoc
          foo: bar
          multiline_string: is
           appropriately
           indented
          another_key: value
        EOF
      )
    end
  end
end
