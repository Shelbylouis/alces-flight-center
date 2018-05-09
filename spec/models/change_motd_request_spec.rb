require 'rails_helper'

RSpec.describe ChangeMotdRequest, type: :model do
  it { is_expected.to validate_presence_of(:motd) }
  it { is_expected.to validate_presence_of(:state) }
  it { is_expected.to belong_to(:case) }
  it { is_expected.to have_many(:change_motd_request_state_transitions) }
end
