require 'rails_helper'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'

  let :site do
    create(
      :site,
      users: [primary_contact, secondary_contact, another_secondary_contact],
      additional_contacts: [additional_contact_1, additional_contact_2]
    )
  end

  let :primary_contact do
    create(
      :primary_contact,
      name: 'Some Contact',
      email: 'some.contact@example.com'
    )
  end
  let :secondary_contact do
    create(
      :secondary_contact,
      name: 'Another Contact',
      email: 'another.contact@example.com'
    )
  end
  let :another_secondary_contact do
    create(
      :secondary_contact,
      name: 'Yet Another Contact',
      email: 'yet.another.contact@example.com'
    )
  end

  let :additional_contact_1 do
    create(
      :additional_contact,
      email: 'some.additional.contact@example.com'
    )
  end
  let :additional_contact_2 do
    create(
      :additional_contact,
      email: 'another.additional.contact@example.com'
    )
  end

  describe '#all_contacts' do
    subject { site.all_contacts }

    it 'should give all contacts and additional contacts' do
      expect(subject).to match_array([
        primary_contact,
        secondary_contact,
        another_secondary_contact,
        additional_contact_1,
        additional_contact_2,
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
      expect(subject).to eq([secondary_contact, another_secondary_contact])
    end
  end
end
