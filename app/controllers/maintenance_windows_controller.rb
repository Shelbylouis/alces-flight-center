class MaintenanceWindowsController < ApplicationController
  def new
    @title = "Request Maintenance"

    @maintenance_window = MaintenanceWindow.new(
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
    window.update!(confirmed_by: current_user)
    support_case = window.case
    confirmation_message = <<~EOF.squish
      Maintenance of #{support_case.associated_model.name} confirmed by
      #{current_user.name}; this #{support_case.associated_model_type} is now
      under maintenance.
    EOF
    support_case.add_rt_ticket_correspondence(confirmation_message)
    redirect_to cluster_path(window.case.cluster)
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
