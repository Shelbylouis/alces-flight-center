require 'rails_helper'

RSpec.describe SiteDecorator do
  let(:site) { create(:site) }

  RSpec.shared_examples 'Site users list' do |args|
    role = args.fetch(:role)
    title = args.fetch(:title)

    it 'indicates what is displayed' do
      expect(subject).to include(
        "<h4>#{title}s</h4>"
      )
    end

    it 'indicates when only single user to display' do
      site.users = [create(role)]

      expect(subject).to include(
        "<h4>#{title}</h4>"
      )
    end

    it 'gives list including each applicable user' do
      user = create(role, name: 'Some User')
      site.users = [user]

      expect(subject).to match(
        /<ul><li>#{user.name}.*<\/li><\/ul>/
      )
    end

    it 'indicates when no applicable users' do
      expect(subject).to include('<em>None</em>')
    end
  end

  describe '#secondary_contacts_list' do
    subject do
      site.decorate.secondary_contacts_list
    end

    it_behaves_like 'Site users list',
      role: :secondary_contact,
      title: 'Secondary site contact'
  end

  describe '#viewers_list' do
    subject do
      site.decorate.viewers_list
    end

    it_behaves_like 'Site users list',
      role: :viewer,
      title: 'Site viewer'
  end
end
