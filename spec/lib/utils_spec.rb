
require 'rails_helper'
require 'utils'

RSpec.describe Utils do
  describe '#generate_password' do
    it 'generates a string of uppercase, lowercase, or digit characters' do
      expect(
        described_class.generate_password(length: 20)
      ).to match(/[a-zA-Z0-9]{20}/)
    end
  end
end
