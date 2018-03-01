
require 'rails_helper'

RSpec.describe 'cluster tabs', type: :feature do
  let :cluster { create(:cluster) }

  let :tabs { page.find('ul.nav-tabs') }
  let :maintenance_tab { tabs.find('li', text: /Maintenance/) }

  before :each do
    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])
  end

  context 'when visiting the cluster page' do
    before :each { visit cluster_path(cluster, as: user) }

    context 'with an admin user' do
      let :user { create(:admin) }

      it 'has a dropdown menu for maintenance tab' do
        expect(maintenance_tab).to match_css('.dropdown')
        expect(maintenance_tab.first('div')).to match_css('.dropdown-menu')
      end

      it 'has a link to the existing maintenance' do
        path = cluster_maintenance_windows_path(cluster)
        expect(maintenance_tab).to have_link(href: path)
      end

      it 'has a link to request maintenance' do
        path = new_cluster_maintenance_window_path(cluster)
        expect(maintenance_tab).to have_link(href: path)
      end
    end
  end
end

