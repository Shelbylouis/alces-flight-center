require 'rails_helper'

RSpec.describe Tier, type: :model do
  it { is_expected.to validate_presence_of(:fields) }
  it { is_expected.to validate_presence_of(:level) }

  it do
    is_expected.to validate_numericality_of(:level)
      .only_integer
      .is_greater_than_or_equal_to(0)
      .is_less_than_or_equal_to(3)
  end
end
