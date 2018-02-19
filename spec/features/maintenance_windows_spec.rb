require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  let :support_case { create(:case_with_component) }
  let :component { support_case.component }
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

    let :request_link_path do
      request_maintenance_window_case_path(support_case.id)
    end
    let :end_link_path do
      end_maintenance_window_case_path(support_case.id)
    end

    it 'can request maintenance in association with different Case for Cluster' do
      cluster = create(:cluster)
      component = create(:component, cluster: cluster)
      case_subject = 'Unrelated case'
      unrelated_case = create(:case, cluster: cluster, subject: case_subject)

      visit cluster_path(cluster, as: user)
      component_maintenance_link = page.find_link(
        href: new_component_maintenance_window_path(component)
      )
      component_maintenance_link.click

      select case_subject
      click_button 'Request Maintenance'

      new_window = unrelated_case.maintenance_windows.first
      expect(new_window.requested_by).to eq user
      expect(new_window).to be_requested
      expect(current_path).to eq(cluster_path(cluster))
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

    it 'can confirm a requested maintenance window' do
      window = create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: window.case.rt_ticket_id,
        text: /Maintenance.*#{component.name}.*confirmed by #{user_name}.*component.*now under maintenance/
      )

      visit cluster_path(component.cluster, as: user)
      button_text = "Unconfirmed"
      click_button(button_text)

      expect(page).not_to have_button(button_text)
      expect(page.all('table')[1]).to have_text(user_name)
      expect(window.reload.confirmed_by).to eq(user)
    end
  end
end
