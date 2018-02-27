class MaintenanceWindowsController < ApplicationController
  def new
    @title = "Request Maintenance"

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
      @maintenance_window = MaintenanceWindow.create!(maintenance_window_params)
      @maintenance_window.request!(current_user)
    end
    flash[:success] = 'Maintenance requested.'
    redirect_to @maintenance_window.associated_cluster
  end

  def confirm
    window = MaintenanceWindow.find(params[:id])
    window.confirm!(current_user)
    flash[:success] = 'Requested maintenance confirmed.'
    redirect_to cluster_path(window.associated_cluster)
  end

  def reject
    window = MaintenanceWindow.find(params[:id])
    window.reject!(current_user)
    flash[:success] = 'Requested maintenance rejected.'
    redirect_to cluster_path(window.associated_cluster)
  end

  def cancel
    window = MaintenanceWindow.find(params[:id])
    window.cancel!(current_user)
    flash[:success] = 'Requested maintenance cancelled.'
    redirect_to cluster_path(window.associated_cluster)
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

  def suggested_requested_start
    1.day.from_now.at_midnight
  end

  def suggested_requested_end
    suggested_requested_start.advance(days: 1)
  end
end
