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

    let :cluster { create(:cluster) }
    let! :component { create(:component, cluster: cluster) }

    let :component_maintenance_path do
      new_component_maintenance_window_path(component)
    end

    it 'can navigate to maintenance request form from Cluster dashboard' do
      visit cluster_path(cluster, as: user)

      component_maintenance_link = page.find_link(
        href: component_maintenance_path
      )
      component_maintenance_link.click

      expect(current_path).to eq(component_maintenance_path)
    end

    describe 'maintenance request form' do
      let! :cluster_case do
        create(:case, cluster: cluster, subject: 'Some case')
      end

      def fill_in_datetime_selects(identifier, with:)
        select with.year.to_s, from: "#{identifier}-datetime-select-year"
        month_name = with.strftime('%B')
        select month_name, from: "#{identifier}-datetime-select-month"
        select with.day.to_s, from: "#{identifier}-datetime-select-day"
        select with.hour.to_s, from: "#{identifier}-datetime-select-hour"
      end

      def requested_start_element
        find(:test_element, :requested_start)
      end

      def requested_end_element
        find(:test_element, :requested_end)
      end

      before :each do
        visit new_component_maintenance_window_path(component, as: user)
      end

      it 'can request maintenance in association with any Case for Cluster' do
        requested_start = DateTime.new(2022, 9, 10, 13, 0)
        requested_end = DateTime.new(2023, 9, 20, 13, 0)

        select cluster_case.subject
        fill_in_datetime_selects 'requested-start', with: requested_start
        fill_in_datetime_selects 'requested-end', with: requested_end
        click_button 'Request Maintenance'

        new_window = cluster_case.maintenance_windows.first
        expect(new_window).to be_requested
        expect(new_window.requested_by).to eq user
        expect(new_window.requested_start).to eq requested_start
        expect(new_window.requested_end).to eq requested_end
        expect(current_path).to eq(cluster_path(cluster))
        expect(find('.alert')).to have_text(/Maintenance requested/)
      end

      it 'does not initially have invalid elements' do
        [requested_start_element, requested_end_element].each do |element|
          expect(element).not_to have_selector('select', class: 'is-invalid')
        end
      end

      it 're-renders form with error when invalid date entered' do
        requested_end_in_past = DateTime.new(2016, 9, 20, 13)

        expect do
          fill_in_datetime_selects 'requested-end', with: requested_end_in_past
          click_button 'Request Maintenance'
        end.not_to change(MaintenanceWindow, :count)

        expect(current_path).to eq(component_maintenance_path)
        expect(
          find('.alert')
        ).to have_text(/Unable to request this maintenance/)
        invalidated_selects =
          requested_end_element.all('select', class: 'is-invalid')
        expect(invalidated_selects.length).to eq(5)
        expect(requested_end_element.find('.invalid-feedback')).to have_text(
          'Must be after start; cannot be in the past'
        )
        expect(
          requested_start_element
        ).not_to have_selector('select', class: 'is-invalid')
      end
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
