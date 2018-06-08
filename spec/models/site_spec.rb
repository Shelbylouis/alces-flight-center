require 'rails_helper'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_column'

  let :site do
    create(
      :site,
      users: [primary_contact, secondary_contact],
      additional_contacts: [additional_contact]
    )
  end

  let :primary_contact do
    create(:primary_contact, email: 'some.contact@example.com')
  end

  let :secondary_contact do
    create(:secondary_contact, email: 'another.contact@example.com')
  end

  let(:additional_contact) { create(:additional_contact) }

  describe '#email_recipients' do
    subject { site.email_recipients }

    it 'should give emails for all Site users and additional contacts' do
      expect(subject).to match_array([
        primary_contact.email,
        secondary_contact.email,
        additional_contact.email,
      ])
    end
  end

  describe '#primary_contact' do
    subject { site.primary_contact }

    it 'gives Site primary contact' do
      expect(subject).to eq(primary_contact)
    end
  end
end
