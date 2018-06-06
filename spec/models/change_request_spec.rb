require 'rails_helper'

RSpec.describe ChangeRequest, type: :model do

  let(:my_case) { create(:open_case, tier_level: 3) }

  it 'sets case tier to 4 on creation' do
    create(:change_request, case: my_case)

    my_case.reload
    expect(my_case.tier_level).to eq 4
  end

end
