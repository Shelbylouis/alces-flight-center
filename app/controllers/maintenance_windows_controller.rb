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
    redirect_to @maintenance_window.associated_model.cluster
  end

  def confirm
    window = MaintenanceWindow.find(params[:id])
    window.confirm!(current_user)
    associated_model = window.associated_model
    confirmation_message = <<~EOF.squish
      Maintenance of #{associated_model.name} confirmed by
      #{current_user.name}; this #{associated_model.readable_model_name} is now
      under maintenance.
    EOF
    window.add_rt_ticket_correspondence(confirmation_message)
    redirect_to cluster_path(associated_model.cluster)
  end

  def end
    window = MaintenanceWindow.find(params[:id])
    window.end!
    associated_model = window.associated_model
    window.add_rt_ticket_correspondence(
      "#{associated_model.name} is no longer under maintenance."
    )
    redirect_to cluster_path(window.associated_model.cluster)
  end

  private

  def maintenance_window_params
    params.require(:maintenance_window).permit(
      :cluster_id, :component_id, :service_id, :case_id
    ).merge(
      user: current_user
    ).to_h.symbolize_keys
  end
end
