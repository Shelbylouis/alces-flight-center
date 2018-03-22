require 'rails_helper'

RSpec.shared_examples 'maintenance form error handling' do |form_action|
  it 'does not initially have invalid elements' do
    [requested_start_element, requested_end_element].each do |element|
      expect(element).not_to have_selector('select', class: 'is-invalid')
    end
  end

  it 're-renders form with error when invalid date entered' do
    original_path = current_path
    requested_end_in_past = DateTime.new(2016, 9, 20, 13)

    expect do
      fill_in_datetime_selects 'requested-end', with: requested_end_in_past
      submit_button_text = "#{form_action.titlecase} Maintenance"
      click_button submit_button_text
    end.not_to change(MaintenanceWindow, :all)

    expect(current_path).to eq(original_path)
    expect(
      find('.alert')
    ).to have_text(/Unable to #{form_action} this maintenance/)
    invalidated_selects =
      requested_end_element.all('select', class: 'is-invalid')
    expect(invalidated_selects.length).to eq(5)
    expect(requested_end_element.find('.invalid-feedback')).to have_text(
      'Must be after start; cannot be in the past'
    )
  end
end

RSpec.shared_examples 'confirmation form' do
  before :each do
    visit confirm_service_maintenance_window_path(
      window,
      service_id: service.id,
      as: user
    )
  end

  include_examples 'maintenance form error handling', 'confirm'

  it 'can confirm requested maintenance' do
    fill_in_datetime_selects 'requested-start', with: valid_requested_start
    fill_in_datetime_selects 'requested-end', with: valid_requested_end
    click_button 'Confirm Maintenance'

    window.reload
    expect(window).to be_confirmed
    expect(window.confirmed_by).to eq user
    expect(window.requested_start).to eq valid_requested_start
    expect(window.requested_end).to eq valid_requested_end
    confirmed_transition = window.transitions.find_by_to(:confirmed)
    expect(confirmed_transition.requested_start).to eq valid_requested_start
    expect(confirmed_transition.requested_end).to eq valid_requested_end
    expect(current_path).to eq(cluster_path(cluster))
    expect(find('.alert')).to have_text(/Maintenance confirmed/)
  end
end

RSpec.feature "Maintenance windows", type: :feature do
  let :support_case { create(:case_with_component) }
  let :component { support_case.component }
  let :cluster { support_case.cluster }
  let :site { support_case.site }

  let :valid_requested_end { DateTime.new(2023, 9, 20, 13, 0) }
  let :valid_requested_start { DateTime.new(2022, 9, 10, 13, 0) }

  before :each do
    # The only way I can get Capybara to use the correct URL; may be a better
    # way though.
    default_url_options[:host] = Rails.application.routes.default_url_options[:host]

    # Prevent attempting to retrieve documents from S3 when Cluster page
    # visited.
    allow_any_instance_of(Cluster).to receive(:documents).and_return([])
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

  context 'when user is an admin' do
    let :user_name { 'Steve User' }
    let :user { create(:admin, name: user_name) }

    let :cluster { create(:cluster) }
    let! :component { create(:component, cluster: cluster) }

    let :component_maintenance_path do
      new_component_maintenance_window_path(component)
    end

    it 'can navigate to maintenance request form from Cluster dashboard Components tab' do
      visit cluster_components_path(cluster, as: user)

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

      before :each do
        visit new_component_maintenance_window_path(component, as: user)
      end

      include_examples 'maintenance form error handling', 'request'

      it 'can request maintenance in association with any Case for Cluster' do
        select cluster_case.subject
        fill_in_datetime_selects 'requested-start', with: valid_requested_start
        fill_in_datetime_selects 'requested-end', with: valid_requested_end
        click_button 'Request Maintenance'

        new_window = cluster_case.maintenance_windows.first
        expect(new_window).to be_requested
        expect(new_window.requested_by).to eq user
        expect(new_window.requested_start).to eq valid_requested_start
        expect(new_window.requested_end).to eq valid_requested_end
        expect(current_path).to eq(cluster_path(cluster))
        expect(find('.alert')).to have_text(/Maintenance requested/)
      end
    end

    it 'can cancel requested maintenance' do
      window = create(:requested_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)
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

    it 'can navigate to confirmation form for requested maintenance' do
      window = create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(component.cluster, as: user)
      button_link_text = 'Unconfirmed'
      click_link(button_link_text)

      expected_path = confirm_component_maintenance_window_path(
        window, component_id: component
      )
      expect(current_path).to eq expected_path
    end

    describe 'maintenance confirmation form' do
      let :window do
        create(
          :requested_maintenance_window,
          service: service,
          case: support_case,
        )
      end
      let :service { create(:service, cluster: cluster) }

      include_examples 'confirmation form'
    end

    it 'can reject requested maintenance' do
      window = create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(cluster, as: user)
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
