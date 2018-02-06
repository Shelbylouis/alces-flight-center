require 'rails_helper'

RSpec.describe Expansion, type: :model do
  context 'with an invalid Expansion' do
    subject { Expansion.create.errors.messages }

    # The type field specifies which flavour of Expansion is required
    # However it is left blank in the base Expansion model
    it 'a base Expansion can not be created' do
      expect(subject).to include(:type)
    end

    it 'must have slot set' do
      expect(subject).to include(:slot)
    end
  end

  describe 'ports' do
    # NOTE: DefaultExpansion is used as a stand in as the type must be set
    # However it is testing the underlining Expansion validation
    it 'defaults to zero if not provided' do
      expansion = create(:default_expansion, ports: '')
      expect(expansion).to be_valid
      expect(expansion.ports).to eq 0
    end
  end
end

