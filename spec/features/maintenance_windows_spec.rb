require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  context 'when user is an admin' do
    let :user_name { 'Steve User' }
    let :user { create(:admin, name: user_name) }

    let :cluster_name { 'Some Cluster' }
    let :support_case do
      create(
        :case,
        cluster: create(:cluster, name: cluster_name)
      )
    end

    let :start_link_path do
      request_maintenance_window_case_path(support_case.id)
    end
    let :end_link_path do
      end_maintenance_window_case_path(support_case.id)
    end

    it 'can switch a Case to/from under maintenance' do
      visit site_cases_path(support_case.site, as: user)

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /#{cluster_name}.*under maintenance.*#{user_name}/
      )

      start_link = page.find_link(href: start_link_path)
      expect(start_link).to have_css('.fa-wrench.interactive-icon')
      start_link.click
      expect(support_case).to be_under_maintenance
      expect(page).not_to have_link(href: start_link_path)

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /#{cluster_name}.*no longer under maintenance/
      )

      end_link = page.find_link(href: end_link_path)
      expect(end_link).to have_css('.fa-heartbeat.interactive-icon')
      end_link.click
      expect(support_case).not_to be_under_maintenance
      expect(page).not_to have_link(href: end_link_path)
    end
  end
end
