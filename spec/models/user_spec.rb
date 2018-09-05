require 'rails_helper'

RSpec.shared_examples 'test every role' do |role_value_hash|
  role_value_hash.stringify_keys!
  unhandled_roles = User::ROLES - role_value_hash.keys
  if unhandled_roles.present?
    raise "Unhandled roles: #{unhandled_roles.join(', ')}"
  end

  role_value_hash.each do |role, value|
    context "when role is '#{role}'" do
      let(:role) { role }

      it { is_expected.to eq value }
    end
  end
end

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
  roles.each do |role_under_test|
    role_query_method = role_under_test + '?'

    describe "##{role_query_method}" do
      subject do
        build(:user, role: role).public_send(role_query_method)
      end

      expected_results = {
        admin: false,
        primary_contact: false,
        secondary_contact: false,
        viewer: false,
      }.merge(role_under_test.to_sym => true)

      include_examples 'test every role', expected_results
    end
  end

  describe '#contact?' do
    subject do
      build(:user, role: role).contact?
    end

    include_examples 'test every role', {
      admin: false,
      primary_contact: true,
      secondary_contact: true,
      viewer: false,
    }
  end

  describe '#editor?' do
    subject do
      build(:user, role: role).editor?
    end

    include_examples 'test every role', {
      admin: true,
      primary_contact: true,
      secondary_contact: true,
      viewer: false,
    }
  end

  describe '#site_user?' do
    subject do
      build(:user, role: role).site_user?
    end

    include_examples 'test every role', {
      admin: false,
      primary_contact: true,
      secondary_contact: true,
      viewer: true,
    }
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

  describe '#from_jwt-token' do
    let(:email_address) { 'some.user@example.com' }
    let!(:user) { create(:contact, email: email_address) }

    let(:valid_token) {
      ::JsonWebToken.encode(email: email_address)
    }

    it 'returns user from valid token' do
      expect(User.from_jwt_token(valid_token)).to eq user
    end

    it 'returns nil from invalid token' do
      # A primitive way of invalidating the token but it works...
      invalid_token = valid_token << 'F'
      expect(User.from_jwt_token(invalid_token)).to eq nil
    end
  end

  describe '#reassign_cases_if_necessary' do
    let(:site) { create(:site) }
    let(:cluster) { create(:cluster, site: site) }
    let(:primary) { create(:primary_contact, site: site) }
    let!(:user) { create(:secondary_contact, site: site) }
    let!(:kase) { create(:open_case, cluster: cluster, contact: user) }

    def demote_contact
      user.role = 'viewer'
      user.save!
    end

    it 'unassigns cases from user when demoted to viewer' do
      expect(user.assigned_cases.count).to eq 1

      primary
      demote_contact
      user.reload

      expect(user.assigned_cases.count).to eq 0
    end

    it 'reassigns cases to primary contact when user is demoted to viewer' do
      expect(primary.assigned_cases.count).to eq 0

      demote_contact
      kase.reload
      primary.reload

      expect(primary.assigned_cases.count).to eq 1
    end
  end

  describe '#validates_viewer_case_assignment' do

    RSpec.shared_examples 'validation passes' do
      it 'passes validation' do
        expect(user).to be_valid
      end
    end

    context 'when user is admin' do
      let(:user) { create(:admin) }

      context 'with no cases assigned' do
        include_examples 'validation passes'
      end

      context 'with cases assigned' do
        let!(:kase) { create(:open_case, assignee: user) }

        include_examples 'validation passes'
      end
    end

    context 'when user is contact' do
      let(:user) { create(:contact) }
      let(:cluster) { create(:cluster, site: user.site) }

      context 'with no cases assigned' do
        include_examples 'validation passes'
      end

      context 'with cases assigned' do
        let!(:kase) { create(:open_case, contact: user, cluster: cluster) }

        include_examples 'validation passes'
      end
    end

    context 'when user is viewer' do
      let(:user) { create(:viewer) }
      let(:cluster) { create(:cluster, site: user.site) }

      context 'with no cases assigned' do
        include_examples 'validation passes'
      end

      context 'with cases assigned' do
        let!(:kase) { create(:open_case, contact: user, cluster: cluster) }

        it 'fails validation' do
          expect(user).not_to be_valid
          expect(user.errors.messages).to include(
                                            cases: ['must be empty for a viewer']
                                          )
        end
      end
    end
  end
end
