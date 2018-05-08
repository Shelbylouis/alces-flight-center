require 'rails_helper'

RSpec.describe ChangeMotdRequest, type: :model do
  it { is_expected.to validate_presence_of(:motd) }
  it { is_expected.to belong_to(:case) }
end
