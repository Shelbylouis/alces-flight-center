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

  describe '#secondary_contacts_info' do
    subject { site.secondary_contacts_info }

    it { is_expected.to eq "#{secondary_contact.info}, #{another_secondary_contact.info}" }
  end

  describe '#additional_contacts_info' do
    subject { site.additional_contacts_info }

    it { is_expected.to eq "#{additional_contact_1.email}, #{additional_contact_2.email}" }
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

  describe '#managed_clusters' do
    it 'gives all managed Clusters for Site' do
      site = create(:site)
      create(:managed_cluster, site: site, name: 'First managed')
      create(:advice_cluster, site: site, name: 'Advice')
      create(:managed_cluster, site: site, name: 'Second managed')

      managed_cluster_names = site.managed_clusters.map(&:name)

      expect(managed_cluster_names).to match_array(
        ['First managed', 'Second managed']
      )
    end
  end
end
