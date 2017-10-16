require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#info' do
    let :user do
      create(:user, name: 'Some User', email: 'some.user@example.com')
    end

    subject { user.info }

    it { is_expected.to eq 'Some User <some.user@example.com>' }
  end
end
