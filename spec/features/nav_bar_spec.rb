
require 'rails_helper'

RSpec.feature 'Navigation Bar', type: :feature do
  let :nav_bar { find_by_id('top-level-navigation-bar') }
  let :site_nav_bar { nav_bar.all('ul').first }
  let :site_nav_items { site_nav_bar.all('li') }

  let :site { create(:site) }
  let :contact { create(:primary_contact, site: site) }
  let :cluster { create(:cluster, site: site) }

  before :each do
    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])
  end

  def visit_subject(path_helper)
    visit send(path_helper, subject, as: user)
  end

  shared_examples 'a navigation bar' do
    it 'has the navigation bar' do
      expect(nav_bar.tag_name).to eq('nav')
    end

    it 'has a link to the root site in the first location' do
      expect(site_nav_items[0]).to have_link(href: '/')
    end

    xit 'has the correct number of site links' do
      expect(site_nav_items.length).to eq(user_nav_links.length + 1)
    end

    # TODO: Make this work for regular users
    xit 'has the correct links' do
      # TODO: DO NOT USE SUBJECT HERE
      subject.each_with_index do |link, index|
        expect(site_nav_items[index + 1]).to have_link(href: link)
      end
    end
  end

  shared_examples 'navigate to sites' do
    context 'when visiting the root site' do
      let :expected_cluster_links { [] }
      before :each { visit (root_path as: user) }
      it_behaves_like 'a navigation bar'
    end

    context 'when visiting a cluster page' do
      subject { cluster }
      before :each { visit_subject :cluster_path }
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
    let :user { contact }
    let :cluster_nav_items do
      return [] if site_nav_items.length < 1
      site_nav_items[1..-1]
    end
    include_examples 'navigate to sites'
  end
end

