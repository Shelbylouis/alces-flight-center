
require 'rails_helper'

RSpec.feature 'Navigation Bar', type: :feature do
  let(:nav_bar) { first('nav.product-bar') }
  let(:site_nav_bar) { nav_bar.all('ul').first }
  let(:site_nav_items) { site_nav_bar.all('li') }

  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  def visit_subject(path_helper)
    visit send(path_helper, subject, as: user)
  end

  shared_examples 'a common navigation bar' do
    # Condensed tests to save on setup time
    it 'has a nav bar with the root link in the first location' do
      expect(nav_bar.tag_name).to eq('nav')
      expect(site_nav_items[0]).to have_link(href: '/')
    end

    it 'only the last (non-picker) link is active' do
      active_css = '.nav-link--active'

      if site_nav_items.last&.text == 'Choose site'
        expect(site_nav_items.length).to eq 2
        expect(site_nav_items.first).to have_css active_css
        expect(site_nav_items.last).not_to have_css active_css
      else
        site_nav_items[0..-2].each do |item|
          expect(item).not_to have_css active_css
        end
        expect(site_nav_items.last).to have_css active_css
      end
    end
  end

  shared_examples 'a cluster navigation bar' do
    it_behaves_like 'a common navigation bar'

    it 'sets the site link (in 2nd position) if user is an admin' do
      expect_link = expect(site_nav_items[1])
      have_link_condition = have_link(href: site_path(site))
      if user.admin?
        expect_link.to have_link_condition
      else
        expect_link.not_to have_link_condition
      end
    end

    # Condensed tests to save on setup time
    it 'has the correct links (and number)' do
      number_cluster_links = expected_cluster_links.length
      expect(cluster_nav_items.length).to eq(number_cluster_links)

      expected_cluster_links.each_with_index do |link, index|
        expect(cluster_nav_items[index]).to have_link(href: link)
      end
    end
  end

  shared_examples 'navigate to sites' do
    context 'when visiting the root site' do
      let(:expected_cluster_links) { [] }

      before(:each) { visit (root_path as: user) }

      it_behaves_like 'a common navigation bar'

      it 'only has the root navigation link (and site picker for admins)' do
        expect(site_nav_items.length).to eq(user&.admin? ? 2 : 1)
      end
    end

    context 'when visiting a cluster page' do
      subject { cluster }

      let(:expected_cluster_links) { [cluster_path(subject)] }

      before(:each) { visit_subject :cluster_path }

      it_behaves_like 'a cluster navigation bar'
    end

    context 'when visiting a component_group' do
      subject { create(:component_group, cluster: cluster) }

      let :expected_cluster_links do
        [cluster_path(subject.cluster), component_group_path(subject)]
      end

      before(:each) { visit_subject :component_group_path }

      it_behaves_like 'a cluster navigation bar'
    end

    context 'when visiting a component' do
      subject { create(:component, cluster: cluster) }

      let :expected_cluster_links do
        [ cluster_path(subject.cluster),
          component_group_path(subject.component_group),
          component_path(subject) ]
      end

      before(:each) { visit_subject :component_path }

      it_behaves_like 'a cluster navigation bar'
    end

    context 'when visiting a service' do
      subject { create(:service, cluster: cluster) }

      let :expected_cluster_links do
        [ cluster_path(subject.cluster), service_path(subject) ]
      end

      before(:each) { visit_subject :service_path }

      it_behaves_like 'a cluster navigation bar'
    end
  end

  context 'with an admin logged in' do
    let(:user) { create(:admin) }

    let :cluster_nav_items do
      return [] if site_nav_items.length < 2
      site_nav_items[2..-1]
    end

    include_examples 'navigate to sites'

    context 'when visiting the site page' do
      subject { site }

      let(:expected_cluster_links) { [] }

      before(:each) { visit_subject :site_path }

      it_behaves_like 'a cluster navigation bar'
    end
  end

  non_admin_roles = User::ROLES - ['admin']

  non_admin_roles.each do |role|
    context "with a #{role} logged in" do
      let(:user) { create(role, site: site) }

      let :cluster_nav_items do
        return [] if site_nav_items.length < 1
        site_nav_items[1..-1]
      end

      include_examples 'navigate to sites'
    end
  end
end

