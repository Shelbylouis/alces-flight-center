
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

    # TODO: Make this spec cleaner
    it 'sets the site link (in 2nd position) if user is an admin' do
      not_root_path = (page.current_path != '/')
      expect_link = expect(site_nav_items[1])
      have_link_condition = have_link(href: site_path(site))
      if user.admin? && not_root_path
        expect_link.to have_link_condition
      elsif not_root_path
        expect_link.not_to have_link_condition
      end
    end

    it 'has the correct number of cluster links' do
      number_cluster_links = expected_cluster_links.length
      expect(cluster_nav_items.length).to eq(number_cluster_links)
    end

    it 'has the correct links' do
      expected_cluster_links.each_with_index do |link, index|
        expect(cluster_nav_items[index]).to have_link(href: link)
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
      let :expected_cluster_links { [cluster_path(subject)] }
      before :each { visit_subject :cluster_path }
      it_behaves_like 'a navigation bar'
    end

    context 'when visiting a component_group' do
      subject { create(:component_group, cluster: cluster) }
      let :expected_cluster_links do
        [cluster_path(subject.cluster), component_group_path(subject)]
      end
      before :each { visit_subject :component_group_path }
      it_behaves_like 'a navigation bar'
    end

    context 'when visiting a component' do
      subject { create(:component, cluster: cluster) }
      let :expected_cluster_links do
        [ cluster_path(subject.cluster),
          component_group_path(subject.component_group),
          component_path(subject) ]
      end
      before :each { visit_subject :component_path }
      it_behaves_like 'a navigation bar'
    end

    context 'when visiting a service' do
      subject { create(:service, cluster: cluster) }
      let :expected_cluster_links do
        [ cluster_path(subject.cluster), service_path(subject) ]
      end
      before :each { visit_subject :service_path }
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

