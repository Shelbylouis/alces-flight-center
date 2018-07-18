require 'rails_helper'

RSpec.describe ChangeRequest, type: :model do

  describe '#finalised?' do

    FINAL_STATES = %w(declined completed).freeze

    it 'reports final states as finalised' do

      ChangeRequest.state_machine.states.map(&:name).each do |state|
        cr = create(:change_request, state: state)
        expect(cr.finalised?).to eq(FINAL_STATES.include?(state.to_s))
      end
    end
  end

  it do
    is_expected.to validate_numericality_of(:credit_charge)
      .only_integer
      .is_greater_than_or_equal_to(0)
  end

end
