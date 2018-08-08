class MaintenanceWindowsController < ApplicationController
  decorates_assigned :maintenance_window
  before_action :format_requested_start_fields, only: [:create, :confirm_submit]

  def new
    @case = Case.find_from_id!(params[:case_id])
    @maintenance_window = MaintenanceWindow.new(
      initial_maintenance_window_params.merge(
        maintenance_window_case_params(@case)
      )
    )
    @date = default_requested_start
    authorize @maintenance_window
  end

  def create
    event = mandatory? ? :mandate : :request
    action = mandatory? ? :schedule : :request
    @case = Case.find_from_id!(params[:case_id])
    @date = params['maintenance_window']['requested_start']

    handle_form_submission(action: action, template: :new) do
      @maintenance_window = MaintenanceWindow.new(
        request_maintenance_window_params.merge(
          maintenance_window_case_params(@case)
        )
      )
      authorize @maintenance_window
      ActiveRecord::Base.transaction do
        @maintenance_window.save!
        @maintenance_window.send("#{event}!", current_user)
      end
    end
  end

  def confirm
    @maintenance_window = MaintenanceWindow.find(params[:id])
    @date = @maintenance_window.requested_start
    authorize @maintenance_window

    # Validate window as if it was confirmed without changes up front, so can
    # display any invalid fields which will require changing on initial page
    # load.
    validate_as_if_confirmed(@maintenance_window)
  end

  def confirm_submit
    handle_form_submission(action: :confirm, template: :confirm) do
      @maintenance_window = MaintenanceWindow.find(params[:id])
      authorize @maintenance_window
      @maintenance_window.assign_attributes(confirm_maintenance_window_params)
      @maintenance_window.confirm!(current_user)
    end
  end

  def reject
    transition_window(:reject)
  end

  def cancel
    transition_window(:cancel)
  end

  def end
    transition_window(:end)
  end

  def extend
    transition_window(
      :extend_duration,
      new_state_message: 'duration extended'
    ) do |window|
      window.duration += params[:additional_days].to_i
    end
  end

  private

  REQUEST_PARAM_NAMES = [
    :requested_start,
    :duration,
  ].freeze

  CONFIRM_PARAM_NAMES = [
    :requested_start,
  ].freeze

  def initial_maintenance_window_params
    {
      requested_start: default_requested_start,
      duration: 1,
    }
  end

  def request_maintenance_window_params
    params.require(:maintenance_window).permit(REQUEST_PARAM_NAMES)
  end

  def confirm_maintenance_window_params
    params.require(:maintenance_window).permit(CONFIRM_PARAM_NAMES)
  end

  def maintenance_window_case_params(kase)
    # We want to inherit the _current_ associated cluster parts from @case
    # (e.g. if the case gets changed later, we want the MW to remain
    # the same as when it was created)
    {
      case: kase,
      clusters: kase.clusters,
      services: kase.services,
      component_groups: kase.component_groups,
      components: kase.components
    }
  end

  def default_requested_start
    # Default is 9am on next business day.
    1.business_day.from_now.at_beginning_of_day.advance(hours: 9)
  end

  def mandatory?
    !!params[:mandatory]
  end

  def handle_form_submission(action:, template:)
    yield

    flash[:success] = "Maintenance #{past_tense_of(action)}."
    if action == :confirm
      redirect_to cluster_maintenance_windows_path(@maintenance_window.cluster)
    else
      redirect_to case_path(@maintenance_window.case)
    end
  rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition => e
    flash.now[:error] = "Unable to #{action} this maintenance. #{e}"
    render template
  end

  def past_tense_of(action)
    action.to_s.gsub(/e$/, '') + 'ed'
  end

  def transition_window(event, new_state_message: nil)
    window = MaintenanceWindow.find(params[:id])
    authorize window
    previous_user_facing_state = window.user_facing_state
    cluster = window.cluster

    yield window if block_given?
    window.public_send("#{event}!", current_user)

    flash[:success] = [
      previous_user_facing_state,
      'maintenance',
      new_state_message || window.state,
    ].join(' ').capitalize
    redirect_back fallback_location: cluster_maintenance_windows_path(cluster)
  end

  def validate_as_if_confirmed(window)
    original_state = window.state
    window.state = :confirm
    window.validate
    window.state = original_state
  end

  def format_requested_start_fields
    year, month, day = params['maintenance_window']['requested_start'].split('-')
    params['maintenance_window']['requested_start(1i)'] = year
    params['maintenance_window']['requested_start(2i)'] = month
    params['maintenance_window']['requested_start(3i)'] = day
  end
end
