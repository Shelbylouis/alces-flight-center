require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#secondary_contact?' do
    context 'when User is primary contact' do
      subject { create(:primary_contact).secondary_contact? }
      it { is_expected.to be false }
    end

    context 'when User is secondary contact' do
      subject { create(:secondary_contact).secondary_contact? }
      it { is_expected.to be true }
    end

    context 'when User is admin' do
      subject { create(:admin).secondary_contact? }
      it { is_expected.to be false }
    end
  end
end
