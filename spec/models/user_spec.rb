require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:role) }
  it do is_expected.to validate_inclusion_of(:role).in_array([
    'admin', 'primary_contact', 'secondary_contact', 'viewer'
  ])
  end

  roles = described_class::ROLES
  roles.each do |role|
    role_query_method = role + '?'

    describe "##{role_query_method}" do
      subject do
        build(:user, role: subject_role).public_send(role_query_method)
      end

      context "when role is '#{role}'" do
        let(:subject_role) { role }

        it { is_expected.to be true }
      end

      context "when role is not '#{role}'" do
        another_role = roles.reject{|r| r == role}.sample

        let(:subject_role) { another_role }

        it { is_expected.to be false }
      end
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
