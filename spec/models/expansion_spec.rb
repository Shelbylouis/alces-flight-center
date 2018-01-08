require 'rails_helper'

RSpec.describe Expansion, type: :model do
  # The type field specifies which flavour of Expansion is required
  # However it is left blank in the base Expansion model
  it 'a base Expansion can not be created' do
    expect(Expansion.create.errors.messages).to include(:type)
  end
end
