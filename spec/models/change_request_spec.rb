require 'rails_helper'

RSpec.describe ChangeRequest, type: :model do

  let(:my_case) { create(:open_case, tier_level: 3) }

  it 'sets case tier to 4 on creation' do
    create(:change_request, case: my_case)

    my_case.reload
    expect(my_case.tier_level).to eq 4
  end

  describe '#finalised?' do

    FINAL_STATES = %w(declined completed).freeze

    it 'reports final states as finalised' do

      ChangeRequest.state_machine.states.map(&:name).each do |state|
        cr = create(:change_request, state: state)
        expect(cr.finalised?).to eq(FINAL_STATES.include?(state.to_s))
      end
    end
  end

end
