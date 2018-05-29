require 'rails_helper'

RSpec.describe User, type: :model do
  it { is_expected.to validate_presence_of(:role) }
  it do is_expected.to validate_inclusion_of(:role).in_array([
    'admin', 'primary_contact', 'secondary_contact', 'viewer'
  ])
  end

  describe '#valid?' do
    context 'as admin' do
      subject { create(:admin) }

      it { is_expected.to validate_absence_of(:site) }
    end

    context 'as contact' do
      subject { create(:contact) }

      it { is_expected.to validate_presence_of(:site) }
    end

    context 'as viewer' do
      subject { create(:viewer) }

      it { is_expected.to validate_presence_of(:site) }
    end
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

  describe '#contact?' do
    subject do
      build(:user, role: role).contact?
    end

    context "when role is 'primary_contact'" do
      let (:role) { :primary_contact }

      it { is_expected.to be true }
    end

    context "when role is 'secondary_contact'" do
      let (:role) { :secondary_contact }

      it { is_expected.to be true }
    end

    context "when role is 'admin'" do
      let (:role) { :admin }

      it { is_expected.to be false }
    end

    context "when role is 'viewer'" do
      let (:role) { :viewer }

      it { is_expected.to be false }
    end
  end

  describe '#validates_primary_contact_assignment' do
    subject do
      build(:user, role: 'primary_contact', site: site)
    end

    let(:site) { create(:site) }

    context 'with no existing primary contact for site' do
      it 'should be valid' do
        expect(subject).to be_valid
      end
    end

    context 'with an existing primary contact for site' do
      before :each do
        create(:user, role: 'primary_contact', site: site)
      end

      it 'should be invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to match(
          role: ['primary contact is already set for this site']
        )
      end
    end
  end
end
