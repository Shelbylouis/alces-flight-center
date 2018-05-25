require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:role) }
  it do is_expected.to validate_inclusion_of(:role).in_array([
    'admin', 'primary_contact', 'secondary_contact', 'viewer'
  ])
  end

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

  describe '#validates_primary_contact_assignment' do
    subject do
      build(:user, primary_contact: true)
    end

    context 'with no primary contact' do
      it 'should not error' do
        expect(subject).to be_valid
      end
    end

    context 'with an existing primary contact for the current site' do
      let!(:primary_contact) { create(:user, primary_contact: true, site: subject.site) }

      it 'should error' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to match(
          primary_contact: ['is already set for this site']
        )
      end
    end
  end
end
