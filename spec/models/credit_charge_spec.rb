require 'rails_helper'

RSpec.describe CreditCharge, type: :model do
  it do
    is_expected.to validate_numericality_of(:amount)
      .only_integer
      .is_greater_than_or_equal_to(0)
  end
end
