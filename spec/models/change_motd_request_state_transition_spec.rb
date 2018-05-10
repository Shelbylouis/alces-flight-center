require 'rails_helper'

RSpec.describe ChangeMotdRequestStateTransition, type: :model do
  it { is_expected.to belong_to(:change_motd_request) }
  it { is_expected.to belong_to(:user) }

  describe '#valid?' do
    subject { build(:change_motd_request_state_transition) }

    it { is_expected.to validate_presence_of(:user) }
    it_behaves_like 'it must be initiated by an admin'
  end
end
