
require 'rails_helper'

RSpec.feature Log, type: :feature do
  let :nav_bar { find_by_id('top-level-navigation-bar') }
  let :site_nav_bar { nav_bar.all('ul').first }
  let :site_nav_items { site_nav_bar.all('li') }

  def visit_site(path_helper, scope = nil)
    options = [as: user].tap { |opt| opt.unshift(scope) if scope }
    visit send(path_helper, *options)
  end

  shared_examples 'a navigation bar' do
    it 'has the navigation bar' do
      expect(nav_bar.tag_name).to eq('nav')
    end

    xit 'has the correct number of site links' do
      # Admins have an extract 'all sites' button
      expect(site_nav_items.length).to eq(user_nav_links.length + 1)
    end

    # TODO: Make this work for regular users
    xit 'has the correct links' do
      subject.each_with_index do |link, index|
        expect(site_nav_items[index + 1]).to have_link(href: link)
      end
    end
  end

  shared_examples 'navigate to sites' do
    context 'when visiting the root site' do
      let :expected_cluster_links { [] }
      before :each { visit_site :root_path }
      it_behaves_like 'a navigation bar'
    end
  end

  context 'with an admin logged in' do
    let :user { create(:admin) }
    let :cluster_nav_items do
      return [] if site_nav_items.length < 2
      site_nav_items[2..-1]
    end
    include_examples 'navigate to sites'
  end

  context 'with a regular user logged in' do
    let :user { create(:user, admin: false) }
    let :cluster_nav_items do
      return [] if site_nav_items.length < 1
      site_nav_items[1..-1]
    end
    include_examples 'navigate to sites'
  end
end

