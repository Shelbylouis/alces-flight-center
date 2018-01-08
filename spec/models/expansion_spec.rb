require 'rails_helper'

RSpec.describe Expansion, type: :model do
  context 'with an invalid Expansion' do
    subject { Expansion.create.errors.messages }

    # The type field specifies which flavour of Expansion is required
    # However it is left blank in the base Expansion model
    it 'a base Expansion can not be created' do
      expect(subject).to include(:type)
    end

    it 'must have ports and slot set' do
      expect(subject).to include(:ports)
      expect(subject).to include(:slot)
    end
  end
end

