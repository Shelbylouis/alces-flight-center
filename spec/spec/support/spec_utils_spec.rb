require 'rails_helper'

RSpec.describe SpecUtils do
  describe '#class_factory_identifier' do
    it 'gives correct factory identifier' do
      expect(
        described_class.class_factory_identifier(Component)
      ).to eq(:component)
    end
  end
end
