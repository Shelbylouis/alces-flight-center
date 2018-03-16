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

    it 'can request maintenance in association with any Case for Cluster' do
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

      select '2022', from: 'requested-start-datetime-select-year'
      select 'September', from: 'requested-start-datetime-select-month'
      select '10', from: 'requested-start-datetime-select-day'
      select '13', from: 'requested-start-datetime-select-hour'

      select '2023', from: 'requested-end-datetime-select-year'
      select 'September', from: 'requested-end-datetime-select-month'
      select '20', from: 'requested-end-datetime-select-day'
      select '13', from: 'requested-end-datetime-select-hour'

      click_button 'Request Maintenance'

      new_window = unrelated_case.maintenance_windows.first
      expect(new_window).to be_requested
      expect(new_window.requested_by).to eq user
      expect(new_window.requested_start).to eq DateTime.new(2022, 9, 10, 13, 0)
      expect(new_window.requested_end).to eq DateTime.new(2023, 9, 20, 13, 0)
      expect(current_path).to eq(cluster_path(cluster))
      expect(find('.alert')).to have_text(/Maintenance requested/)
    end

    it 're-renders form with error when invalid date entered' do
      cluster = create(:cluster)
      component = create(:component, cluster: cluster)

      visit new_component_maintenance_window_path(component, as: user)

      requested_end_group = find(:test_element, :requested_end)
      expect(requested_end_group).not_to have_selector('select', class: 'is-invalid')

      select '2022', from: 'requested-start-datetime-select-year'
      select 'September', from: 'requested-start-datetime-select-month'
      select '10', from: 'requested-start-datetime-select-day'
      select '13', from: 'requested-start-datetime-select-hour'

      select '2016', from: 'requested-end-datetime-select-year'
      select 'September', from: 'requested-end-datetime-select-month'
      select '20', from: 'requested-end-datetime-select-day'
      select '13', from: 'requested-end-datetime-select-hour'

      expect do
        click_button 'Request Maintenance'
      end.not_to change(MaintenanceWindow, :count)
      expect(current_path).to eq(new_component_maintenance_window_path(component))
      expect(find('.alert')).to have_text(/Unable to request this maintenance/)

      requested_end_group = find(:test_element, :requested_end)
      invalidated_selects = requested_end_group.all('select', class: 'is-invalid')
      expect(invalidated_selects.length).to eq(5)

      expect(requested_end_group.find('.invalid-feedback')).to have_text(
        'Must be after start; cannot be in the past'
      )

      requested_start_group = find(:test_element, :requested_start)
      expect(requested_start_group).not_to have_selector('select', class: 'is-invalid')
    end

    it 'can cancel requested maintenance' do
      window = create(:requested_maintenance_window, cluster: cluster)

      visit cluster_path(cluster, as: user)
      button_text = 'Cancel'
      click_button(button_text)

      window.reload
      expect(window).to be_cancelled
      expect(window.cancelled_by).to eq user
      expect(current_path).to eq(cluster_path(cluster))
      expect(find('.alert')).to have_text(/maintenance cancelled/)
    end

    it 'cannot see reject button' do
      create(:requested_maintenance_window, cluster: cluster)

      visit cluster_path(cluster, as: user)

      expect(page).not_to have_button('Reject')
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

      visit cluster_path(component.cluster, as: user)
      button_text = "Unconfirmed"
      click_button(button_text)

      window.reload
      expect(window).to be_confirmed
      expect(window.confirmed_by).to eq(user)
      expect(page).not_to have_button(button_text)
      expect(page.all('table')[1]).to have_text(user_name)
      expect(find('.alert')).to have_text(/maintenance confirmed/)
    end

    it 'can reject requested maintenance' do
      window = create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_path(cluster, as: user)
      button_text = 'Reject'

      click_button(button_text)

      window.reload
      expect(window).to be_rejected
      expect(window.rejected_by).to eq user
      expect(current_path).to eq(cluster_path(cluster))
      expect(find('.alert')).to have_text(/maintenance rejected/)
    end

    it 'cannot see cancel button' do
      create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_path(cluster, as: user)

      expect(page).not_to have_button('Cancel')
    end
  end
end
