require 'rails_helper'

RSpec.describe ChangeMotdRequestStateTransition, type: :model do
  it { is_expected.to belong_to(:change_motd_request) }
  it { is_expected.to belong_to(:user) }
end
