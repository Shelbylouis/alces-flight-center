require 'rails_helper'

RSpec.describe Case, type: :model do
  let(:site) { create(:site) }
  let(:other_site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:admin) { create(:admin) }
  let(:site_contact) { create(:contact, site: site) }
  let(:other_contact) { create(:contact, site: other_site) }

  let(:assignee) { admin }
  let(:contact) { site_contact }

  subject do
    build(:case, cluster: cluster, assignee: assignee, contact: contact)
  end

  context 'engineer assignment' do
    context 'when not assigned to anyone' do
      let(:assignee) { nil }
      it { is_expected.to be_valid }
    end

    context 'when assigned to an admin' do
      let(:assignee) { admin }
      it { is_expected.to be_valid }
    end

    context 'when assigned to a user that is not an admin' do
      let(:assignee) { other_contact }
      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to eq(
          assignee: ['must be an admin']
        )
      end
    end
  end

  context 'contact assignment' do
    context 'when not assigned to anyone' do
      let(:contact) { nil }
      it { is_expected.to be_valid }
    end

    context 'when assigned to a contact in this site' do
      let(:contact) { site_contact }
      it { is_expected.to be_valid }
    end

    context 'when assigned to another site\'s contact' do
      let(:contact) { other_contact }
      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to eq(
          contact: ['must belong to this site']
        )
      end
    end

    context 'when assigned to an admin' do
      let(:contact) { admin }
      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to eq(
          contact: ['must belong to this site']
        )
      end
    end
  end
end
