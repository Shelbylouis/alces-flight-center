require 'rails_helper'
require 'shared_examples/canonical_name'
require 'shared_examples/markdown_description'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'

  let :site do
    create(
      :site,
      users: [contact_1, contact_2],
      additional_contacts: [additional_contact_1, additional_contact_2]
    )
  end

  let :contact_1 do
    create(
      :contact,
      name: 'Some Contact',
      email: 'some.contact@example.com'
    )
  end
  let :contact_2 do
    create(
      :contact,
      name: 'Another Contact',
      email: 'another.contact@example.com'
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

  describe '#contacts_info' do
    subject { site.contacts_info }

    it { is_expected.to eq "#{contact_1.info}, #{contact_2.info}" }
  end

  describe '#additional_contacts_info' do
    subject { site.additional_contacts_info }

    it { is_expected.to eq "#{additional_contact_1.email}, #{additional_contact_2.email}" }
  end

  describe '#all_contacts' do
    subject { site.all_contacts }

    it 'should give all contacts and additional contacts' do
      expect(subject).to match_array([
        contact_1,
        contact_2,
        additional_contact_1,
        additional_contact_2,
      ])
    end
  end
end
