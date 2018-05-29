require 'rails_helper'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'

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

  describe '#all_contacts' do
    subject { site.all_contacts }

    it 'should give all contacts and additional contacts' do
      expect(subject).to match_array([
        primary_contact,
        secondary_contact,
        additional_contact,
      ])
    end
  end

  describe '#primary_contact' do
    subject { site.primary_contact }

    it 'gives Site primary contact' do
      expect(subject).to eq(primary_contact)
    end
  end

  describe '#secondary_contacts' do
    subject { site.secondary_contacts }

    it 'gives Site secondary contacts' do
      expect(subject).to match_array([secondary_contact])
    end
  end
end
