require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  let :support_case { create(:case, cluster: cluster) }
  let :cluster { create(:cluster, name: cluster_name) }
  let :cluster_name { 'Some Cluster' }
  let :site { support_case.site }

  context 'when user is an admin' do
    let :user_name { 'Steve User' }
    let :user { create(:admin, name: user_name) }

    let :start_link_path do
      request_maintenance_window_case_path(support_case.id)
    end
    let :end_link_path do
      end_maintenance_window_case_path(support_case.id)
    end

    it 'can switch a Case to/from under maintenance' do
      visit site_cases_path(site, as: user)

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

  context 'when user is contact' do
    let :user_name { 'Some Customer' }
    let :user do
      create(:contact, name: user_name, site: site)
    end

    it 'can confirm an unconfirmed maintenance window' do
      # Prevent attempting to retrieve documents from S3 when Cluster page
      # visited.
      allow_any_instance_of(Cluster).to receive(:documents).and_return([])

      window = create(:unconfirmed_maintenance_window, case: support_case)

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /Maintenance.*#{cluster_name}.*confirmed by #{user_name}.*cluster.*now under maintenance/
      )

      visit cluster_path(cluster, as: user)

      button_text = "Unconfirmed"
      click_button(button_text)

      expect(page).not_to have_button(button_text)
      expect(page.all('table').first).to have_text(user_name)
      expect(window.reload.confirmed_by).to eq(user)
    end
  end
end
