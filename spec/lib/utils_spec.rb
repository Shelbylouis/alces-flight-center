
require 'rails_helper'
require 'utils'

RSpec.describe Utils do
  describe '#rt_format' do
    it 'appropriately formats a hash as text' do
      expect(
        described_class.rt_format(foo: 'bar',
                                  multiline_string: <<-EOF.strip_heredoc,
          is
          appropriately
          indented
          EOF
                                  another_key: 'value')
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

  describe '#generate_password' do
    it 'generates a string of uppercase, lowercase, or digit characters' do
      expect(
        described_class.generate_password(length: 20)
      ).to match(/[a-zA-Z0-9]{20}/)
    end
  end
end
