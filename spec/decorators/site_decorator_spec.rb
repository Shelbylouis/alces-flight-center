require 'rails_helper'

RSpec.describe SiteDecorator do
  describe '#secondary_contacts_list' do
    it 'indicates what is displayed' do
      site = create(:site)

      expect(
        site.decorate.secondary_contacts_list
      ).to include(
        '<h4>Secondary site contacts</h4>'
      )
    end

    it 'indicates when only single contact to display' do
      site = create(:site, users: [create(:secondary_contact)])

      expect(
        site.decorate.secondary_contacts_list
      ).to include(
        '<h4>Secondary site contact</h4>'
      )
    end

    it 'gives list including each secondary contact' do
      secondary_contact = create(:secondary_contact, name: 'Some User')
      site = create(:site, users: [secondary_contact])

      expect(
        site.decorate.secondary_contacts_list
      ).to match(/<ul><li>#{secondary_contact.name}.*<\/li><\/ul>/)
    end

    it 'indicates when no secondary contacts' do
      site = create(:site)

      expect(
        site.decorate.secondary_contacts_list
      ).to include('<em>None</em>')
    end
  end
end
