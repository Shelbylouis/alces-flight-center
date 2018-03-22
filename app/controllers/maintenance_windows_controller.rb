class MaintenanceWindowsController < ApplicationController
  def index
    @title = 'Maintenance'
  end

  def new
    assign_new_maintenance_title

    @maintenance_window = MaintenanceWindow.new(
      cluster_id: params[:cluster_id],
      component_id: params[:component_id],
      service_id: params[:service_id],
      requested_start: suggested_requested_start,
      requested_end: suggested_requested_end,
    )
  end

  def create
    @maintenance_window = MaintenanceWindow.new(
      request_maintenance_window_params
    )
    ActiveRecord::Base.transaction do
      @maintenance_window.save!
      @maintenance_window.request!(current_user)
    end
    flash[:success] = 'Maintenance requested.'
    redirect_to @maintenance_window.associated_cluster
  rescue ActiveRecord::RecordInvalid
    assign_new_maintenance_title
    flash.now[:error] = 'Unable to request this maintenance.'
    render :new
  end

  def confirm
    @maintenance_window = MaintenanceWindow.find(params[:id])

    # Validate window as if it was confirmed without changes up front, so can
    # display any invalid fields which will require changing on initial page
    # load.
    validate_as_if_confirmed(@maintenance_window)
  end

  def confirm_submit
    @maintenance_window = MaintenanceWindow.find(params[:id])
    @maintenance_window.assign_attributes(confirm_maintenance_window_params)
    @maintenance_window.confirm!(current_user)
    flash[:success] = 'Maintenance confirmed.'
    redirect_to @maintenance_window.associated_cluster
  rescue StateMachines::InvalidTransition
    flash.now[:error] = 'Unable to confirm this maintenance.'
    render :confirm
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
    params.require(:maintenance_window).permit(REQUEST_PARAM_NAMES)
  end

  def confirm_maintenance_window_params
    params.require(:maintenance_window).permit(CONFIRM_PARAM_NAMES)
  end

  def assign_new_maintenance_title
    @title = 'Request Maintenance'
  end

  def suggested_requested_start
    1.day.from_now.at_midnight
  end

  def suggested_requested_end
    suggested_requested_start.advance(days: 1)
  end

  def transition_window(event)
    window = MaintenanceWindow.find(params[:id])
    window.public_send("#{event}!", current_user)
    flash[:success] = "Requested maintenance #{window.state}."
    redirect_to cluster_path(window.associated_cluster)
  end

  def validate_as_if_confirmed(window)
    original_state = @maintenance_window.state
    @maintenance_window.state = :confirm
    @maintenance_window.validate
    @maintenance_window.state = original_state
  end
end
