
require 'rails_helper'

RSpec.feature Log, type: :feature do
  let :nav_bar { find_by_id('top-level-navigation-bar') }
  let :site_nav_bar { nav_bar.all('ul').first }
  let :site_nav_items { site_nav_bar.all('li') }

  shared_examples 'a navigation bar' do
    it 'has the navigation bar' do
      expect(nav_bar.tag_name).to eq('nav')
    end

    it 'has the correct number of site links' do
      # Admins have an extract 'all sites' button
      expect(site_nav_items.length).to eq(subject.length + 1)
    end

    # TODO: Make this work for regular users
    it 'has the correct links' do
      subject.each_with_index do |link, index|
        expect(site_nav_items[index + 1]).to have_link(href: link)
      end
    end
  end

  context 'with an admin logged in' do
    def visit_as_admin(path_helper)
      visit send(path_helper, scope, as: create(:admin))
    end

    context 'when visiting the site page' do
      let :scope { create(:site) }
      subject { [site_path(scope)] }

      before :each { visit_as_admin :site_path }
      it_behaves_like 'a navigation bar'
    end
  end
end

