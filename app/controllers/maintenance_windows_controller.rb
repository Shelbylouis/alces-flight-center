class MaintenanceWindowsController < ApplicationController
  decorates_assigned :maintenance_window

  def new
    @maintenance_window = MaintenanceWindow.new(
      initial_maintenance_window_params
    )
    authorize @maintenance_window
  end

  def create
    event = mandatory? ? :mandate : :request
    action = mandatory? ? :schedule : :request

    handle_form_submission(action: action, template: :new) do
      @maintenance_window = MaintenanceWindow.new(request_maintenance_window_params)
      authorize @maintenance_window
      ActiveRecord::Base.transaction do
        @maintenance_window.save!
        @maintenance_window.send("#{event}!", current_user)
      end
    end
  end

  def confirm
    @maintenance_window = MaintenanceWindow.find(params[:id])
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
    :cluster_id,
    :component_id,
    :service_id,
    :case_id,
    :requested_start,
    :duration,
  ].freeze

  CONFIRM_PARAM_NAMES = [
    :requested_start,
  ].freeze

  def initial_maintenance_window_params
    {
      associated_model: @scope,
      case_id: params[:case_id],
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

  def default_requested_start
    # Default is 9am on next business day.
    1.business_day.from_now.at_beginning_of_day.advance(hours: 9)
  end

  def mandatory?
    !!params[:mandatory]
  end

  # XXX if we changed `request` to be accessed at `/request` (rather than
  # `/new`) then we wouldn't need to pass `template` here as it would be the
  # same as `action`.
  def handle_form_submission(action:, template:)
    yield

    flash[:success] = "Maintenance #{past_tense_of(action)}."
    cluster = @maintenance_window.associated_cluster
    redirect_to cluster_maintenance_windows_path(cluster)
  rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
    flash.now[:error] = "Unable to #{action} this maintenance."
    render template
  end

  def past_tense_of(action)
    action.to_s.gsub(/e$/, '') + 'ed'
  end

  def transition_window(event, new_state_message: nil)
    window = MaintenanceWindow.find(params[:id])
    authorize window
    previous_user_facing_state = window.user_facing_state
    cluster = window.associated_cluster

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
end
