class MaintenanceWindowsController < ApplicationController
  def new
    @title = "Request Maintenance"

    @maintenance_window = MaintenanceWindow.new(
      cluster_id: params[:cluster_id],
      component_id: params[:component_id],
      service_id: params[:service_id]
    )
  end

  def create
    @maintenance_window =
      RequestMaintenanceWindow.new(**maintenance_window_params).run
    flash[:success] = 'Maintenance requested.'
    redirect_to @maintenance_window.associated_cluster
  end

  def confirm
    window = MaintenanceWindow.find(params[:id])
    window.confirm!(current_user)
    redirect_to cluster_path(window.associated_cluster)
  end

  def end
    window = MaintenanceWindow.find(params[:id])
    window.end!
    redirect_to cluster_path(window.associated_cluster)
  end

  private

  def maintenance_window_params
    params.require(:maintenance_window).permit(
      :cluster_id, :component_id, :service_id, :case_id
    ).merge(
      requested_by: current_user
    ).to_h.symbolize_keys
  end
end
