class MaintenanceWindowsController < ApplicationController
  decorates_assigned :maintenance_window

  def new
    @maintenance_window = MaintenanceWindow.new(
      default_maintenance_window_params
    )
  end

  def create
    event, action =
      params[:mandatory] ? [:mandate, :schedule] : [:request] * 2
    handle_form_submission(action: action, template: :new) do
      @maintenance_window = MaintenanceWindow.new(request_maintenance_window_params)
      ActiveRecord::Base.transaction do
        @maintenance_window.save!
        @maintenance_window.send("#{event}!", current_user)
      end
    end
  end

  def confirm
    @maintenance_window = MaintenanceWindow.find(params[:id])

    # Validate window as if it was confirmed without changes up front, so can
    # display any invalid fields which will require changing on initial page
    # load.
    validate_as_if_confirmed(@maintenance_window)
  end

  def confirm_submit
    handle_form_submission(action: :confirm, template: :confirm) do
      @maintenance_window = MaintenanceWindow.find(params[:id])
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

  def default_maintenance_window_params
    {
      cluster_id: params[:cluster_id],
      component_id: params[:component_id],
      service_id: params[:service_id],
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

  def transition_window(event)
    window = MaintenanceWindow.find(params[:id])
    cluster = window.associated_cluster
    window.public_send("#{event}!", current_user)
    flash[:success] = "Requested maintenance #{window.state}."
    redirect_back fallback_location: cluster_maintenance_windows_path(cluster)
  end

  def validate_as_if_confirmed(window)
    original_state = window.state
    window.state = :confirm
    window.validate
    window.state = original_state
  end
end
