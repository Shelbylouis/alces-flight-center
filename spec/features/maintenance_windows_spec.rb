require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  let :support_case { create(:case_with_component) }

  let :component { support_case.component }
  let :component_name { component.name }

  let :cluster { support_case.cluster }

  let :site { support_case.site }

  before :each do
    # The only way I can get Capybara to use the correct URL; may be a better
    # way though.
    default_url_options[:host] = Rails.application.routes.default_url_options[:host]

    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])
  end

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
        text: /requested.*#{component_name}.*by #{user_name}.*must be confirmed.*#{cluster_url(cluster)}/
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
        text: /#{component_name}.*no longer under maintenance/
      )

      end_link = page.find_link(href: end_link_path)
      expect(end_link).to have_css('.fa-heartbeat.interactive-icon')
      end_link.click
      expect(support_case).not_to be_under_maintenance
      expect(page).not_to have_link(href: end_link_path)
    end

    it 'can end a confirmed maintenance window' do
      end_time = DateTime.new(2018)
      allow(DateTime).to receive(:current).and_return(end_time)
      window = create(:confirmed_maintenance_window, component: component)
      expect(Case.request_tracker).to receive(:add_ticket_correspondence).with(
        id: window.case.rt_ticket_id,
        text: "#{component.name} is no longer under maintenance."
      )

      visit cluster_path(component.cluster, as: user)
      click_button('End Maintenance')

      expect(window.reload.ended_at).to eq(end_time)
      expect(current_path).to eq(cluster_path(component.cluster))
    end
  end

  context 'when user is contact' do
    let :user_name { 'Some Customer' }
    let :user do
      create(:contact, name: user_name, site: site)
    end

    it 'can confirm an unconfirmed maintenance window' do
      window = create(:unconfirmed_maintenance_window, component: component)

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: window.case.rt_ticket_id,
        text: /Maintenance.*#{component_name}.*confirmed by #{user_name}.*component.*now under maintenance/
      )

      visit cluster_path(component.cluster, as: user)
      button_text = "Unconfirmed"
      click_button(button_text)

      expect(page).not_to have_button(button_text)
      expect(page.all('table').first).to have_text(user_name)
      expect(window.reload.confirmed_by).to eq(user)
    end
  end
end
