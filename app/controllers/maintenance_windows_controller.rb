class MaintenanceWindowsController < ApplicationController
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
    ActiveRecord::Base.transaction do
      @maintenance_window = MaintenanceWindow.create(maintenance_window_params)
      @maintenance_window.request(current_user)
    end
    if @maintenance_window.errors.full_messages.any?
      assign_new_maintenance_title
      flash.now[:error] = 'Unable to request this maintenance.'
      render :new
    else
      flash[:success] = 'Maintenance requested.'
      redirect_to @maintenance_window.associated_cluster
    end
  end

  def confirm
    transition_window(:confirm)
  end

  def reject
    transition_window(:reject)
  end

  def cancel
    transition_window(:cancel)
  end

  private

  PARAM_NAMES = [
    :cluster_id,
    :component_id,
    :service_id,
    :case_id,
    :requested_start,
    :requested_end,
  ].freeze

  def maintenance_window_params
    params.require(:maintenance_window).permit(PARAM_NAMES)
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
end
