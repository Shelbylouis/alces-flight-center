require 'rails_helper'

RSpec.shared_examples 'maintenance form error handling' do |form_action|
  it 're-renders form with error when invalid requested_start entered' do
    original_path = current_path
    requested_start_in_past = Time.new(2016, 9, 20, 13)

    expect do
      fill_in_datetime_selects 'requested-start', with: requested_start_in_past
      submit_button_text = "#{form_action.titlecase} Maintenance"
      click_button submit_button_text
    end.not_to change(MaintenanceWindow, :all)

    expect(current_path).to eq(original_path)
    expect(
      find('.alert')
    ).to have_text("Unable to #{form_action} this maintenance")
    invalidated_selects =
      requested_start_element.all('select', class: 'is-invalid')
    expect(invalidated_selects.length).to eq(5)
    invalid_feedback = requested_start_element.find('.invalid-feedback')
    expect(invalid_feedback).to have_text('Cannot be in the past')
  end
end

RSpec.shared_examples 'maintenance form initially valid' do
  it 'does not initially have invalid elements' do
    [requested_start_element, duration_input_group].each do |element|
      expect(element).not_to have_selector('.is-invalid')
    end
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

  it 'cannot change Case for requested maintenance' do
    case_select = test_element('case-select')

    expect(case_select).to be_disabled
    expect(case_select[:title]).to match(/Case.*cannot be changed/)
  end

  it 'includes correct Case select label' do
    case_select_label = test_element('case-select-label')

    expect(case_select_label).to have_text('Associated Case')
  end

  it 'cannot change duration for requested maintenance' do
    duration_input = test_element('duration-input-group').find('input')

    expect(duration_input).to be_disabled
    expect(duration_input[:title]).to match(/duration.*cannot be changed/)
  end

  it 'does not show mandatory maintenance check box' do
    expect do
      check 'mandatory'
    end.to raise_error Capybara::ElementNotFound
  end

  it 'can confirm requested maintenance' do
    fill_in_datetime_selects 'requested-start', with: valid_requested_start
    click_button 'Confirm Maintenance'

    window.reload
    expect(window).to be_confirmed
    expect(window.confirmed_by).to eq user
    expect(window.requested_start).to eq valid_requested_start
    confirmed_transition = window.transitions.find_by_to(:confirmed)
    expect(confirmed_transition.requested_start).to eq valid_requested_start
    expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
    expect(find('.alert')).to have_text('Maintenance confirmed')
  end
end

RSpec.feature "Maintenance windows", type: :feature do
  let :support_case { create(:case_with_component) }
  let :component { support_case.component }
  let :cluster { support_case.cluster }
  let :site { support_case.site }

  let :valid_requested_start { Time.new(2022, 9, 10, 13, 0) }

  let :reject_button_text { 'Reject' }
  let :end_button_text { 'End' }
  let :cancel_button_text { 'Cancel' }
  let :extend_button_text { 'Extend' }

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
    test_element(:requested_start)
  end

  def duration_input_group
    test_element('duration-input-group')
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
      include ActiveSupport::Testing::TimeHelpers

      let! :cluster_case do
        create(:case, cluster: cluster, subject: 'Some case')
      end

      before :each do
        visit new_component_maintenance_window_path(component, as: user)
      end

      include_examples 'maintenance form error handling', 'request'
      include_examples 'maintenance form initially valid'

      it 'uses correct default values' do
        a_distant_friday = Time.new(2025, 3, 7, 0, 0)
        following_monday_at_9 = a_distant_friday.advance(days: 3, hours: 9)

        travel_to a_distant_friday do
          # Visit page again now we have mocked the time so correct default
          # `requested_start` based on current time is used.
          visit new_component_maintenance_window_path(component, as: user)

          select cluster_case.subject
          click_button 'Request Maintenance'

          new_window = cluster_case.maintenance_windows.first
          expect(new_window.requested_start).to eq following_monday_at_9
          expect(new_window.duration).to eq 1
        end
      end

      it 'includes correct Case select label' do
        case_select_label = test_element('case-select-label')

        expect(case_select_label).to have_text('Case to associate')
      end

      it 'can request maintenance in association with any Case for Cluster' do
        select cluster_case.subject
        fill_in 'Duration', with: 2
        fill_in_datetime_selects 'requested-start', with: valid_requested_start
        click_button 'Request Maintenance'

        new_window = cluster_case.maintenance_windows.first
        expect(new_window).to be_requested
        expect(new_window.requested_by).to eq user
        expect(new_window.duration).to eq 2
        expect(new_window.requested_start).to eq valid_requested_start
        expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
        expect(find('.alert')).to have_text('Maintenance requested')
      end

      it 'can mandate maintenance' do
        select cluster_case.subject
        fill_in 'Duration', with: 2
        fill_in_datetime_selects 'requested-start', with: valid_requested_start
        check 'mandatory'
        click_button 'Request Maintenance'

        new_window = cluster_case.maintenance_windows.first
        expect(new_window).to be_confirmed
        expect(new_window.confirmed_by).to eq user
        expect(new_window.duration).to eq 2
        expect(new_window.requested_start).to eq valid_requested_start
        expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
        expect(find('.alert')).to have_text('Maintenance scheduled')
        expect(page).to have_text(/N\/A.*mandatory maintenance/)
      end

      it 're-renders form with error when invalid duration entered' do
        original_path = current_path

        expect do
          fill_in 'Duration', with: -1
          click_button 'Request Maintenance'
        end.not_to change(MaintenanceWindow, :all)

        expect(current_path).to eq(original_path)
        expect(
          find('.alert')
        ).to have_text('Unable to request this maintenance')
        expect(duration_input_group).to have_css('input.is-invalid')
        invalid_feedback = duration_input_group.find('.invalid-feedback')
        expect(invalid_feedback).to have_text('Must be greater than 0')
      end
    end

    it 'can cancel requested maintenance' do
      window = create(:requested_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)
      click_button(cancel_button_text)

      window.reload
      expect(window).to be_cancelled
      expect(window.cancelled_by).to eq user
      expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
      expect(find('.alert')).to have_text('Requested maintenance cancelled')
    end

    it 'can end started maintenance' do
      window = create(:started_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)
      click_button(end_button_text)

      window.reload
      expect(window).to be_ended
      expect(window.ended_by).to eq user
      expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
      expect(find('.alert')).to have_text('Ongoing maintenance ended')
    end

    it 'cannot see end button for non-started maintenance' do
      create(:confirmed_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(end_button_text)
    end

    it 'cannot see reject button' do
      create(:requested_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(reject_button_text)
    end

    [:confirmed, :started].each do |state|
      it "can extend #{state} maintenance" do
        window = create(
          :maintenance_window,
          state: state,
          cluster: cluster,
          duration: 1
        )
        original_duration = window.duration

        visit cluster_maintenance_windows_path(cluster, as: user)
        fill_in placeholder: 'Additional business days', with: 2
        click_button extend_button_text

        window.reload
        expect(window.state.to_sym).to eq state
        duration_extended_transition =
          window.transitions.where(event: :extend_duration).last
        expect(duration_extended_transition.user).to eq user
        new_duration = window.duration
        expect(new_duration).to eq(original_duration + 2)
        expect(duration_extended_transition.duration).to eq(new_duration)
        expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
        expect(find('.alert')).to have_text('maintenance duration extended')
      end
    end

    it 'cannot see extend form for non-confirmed/started maintenance' do
      create(:requested_maintenance_window, cluster: cluster)

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(extend_button_text)
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
      context 'when maintenance is requested' do
        let :window do
          create(
            :requested_maintenance_window,
            service: service,
            case: support_case,
          )
        end
        let :service { create(:service, cluster: cluster) }

        include_examples 'confirmation form'
        include_examples 'maintenance form initially valid'
      end

      context 'when maintenance is expired' do
        let :window do
          create(
            :expired_maintenance_window,
            service: service,
            case: support_case,
          )
        end
        let :service { create(:service, cluster: cluster) }

        include_examples 'confirmation form'

        it 'displays error if date in past on form load' do
          expect(
            requested_start_element.find('.invalid-feedback')
          ).to have_text(
            'Cannot be in the past'
          )
        end
      end
    end

    it 'can reject requested maintenance' do
      window = create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(cluster, as: user)

      click_button(reject_button_text)

      window.reload
      expect(window).to be_rejected
      expect(window.rejected_by).to eq user
      expect(current_path).to eq(cluster_maintenance_windows_path(cluster))
      expect(find('.alert')).to have_text('Requested maintenance rejected')
    end

    it 'cannot see cancel button' do
      create(
        :requested_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(cancel_button_text)
    end

    it 'cannot see end button' do
      create(
        :started_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(end_button_text)
    end

    it 'cannot see extend form' do
      create(
        :started_maintenance_window,
        component: component,
        case: support_case
      )

      visit cluster_maintenance_windows_path(cluster, as: user)

      expect(page).not_to have_button(extend_button_text)
    end
  end
end
