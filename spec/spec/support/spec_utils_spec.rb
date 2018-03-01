require 'rails_helper'

RSpec.describe SpecUtils do
  describe '#class_factory_identifier' do
    it 'gives correct factory identifier' do
      expect(
        described_class.class_factory_identifier(ComponentType)
      ).to eq(:component_type)
    end
  end
end
