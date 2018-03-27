class MaintenanceWindowsController < ApplicationController
  def new
    @maintenance_window = MaintenanceWindow.new(
      cluster_id: params[:cluster_id],
      component_id: params[:component_id],
      service_id: params[:service_id],
      requested_start: suggested_requested_start,
      requested_end: suggested_requested_end,
    )
  end

  def create
    handle_form_submission(action: :request, template: :new) do
      @maintenance_window = MaintenanceWindow.new(request_maintenance_window_params)
      ActiveRecord::Base.transaction do
        @maintenance_window.save!
        @maintenance_window.request!(current_user)
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
    :requested_end,
  ].freeze

  CONFIRM_PARAM_NAMES = [
    :requested_start,
    :requested_end,
  ].freeze

  def request_maintenance_window_params
    # XXX Get duration from request.
    params.require(:maintenance_window).permit(REQUEST_PARAM_NAMES).merge(duration: 1)
  end

  def confirm_maintenance_window_params
    params.require(:maintenance_window).permit(CONFIRM_PARAM_NAMES)
  end

  def suggested_requested_start
    1.day.from_now.at_midnight
  end

  def suggested_requested_end
    suggested_requested_start.advance(days: 1)
  end

  # XXX if we changed `request` to be accessed at `/request` (rather than
  # `/new`) then we wouldn't need to pass `template` here as it would be the
  # same as `action`.
  def handle_form_submission(action:, template:)
    yield

    flash[:success] = "Maintenance #{action}ed."
    cluster = @maintenance_window.associated_cluster
    redirect_to cluster_maintenance_windows_path(cluster)
  rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
    flash.now[:error] = "Unable to #{action} this maintenance."
    render template
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
