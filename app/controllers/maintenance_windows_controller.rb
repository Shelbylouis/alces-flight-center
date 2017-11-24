class MaintenanceWindowsController < ApplicationController
  def confirm
    window = MaintenanceWindow.find(params[:id])
    window.update!(confirmed_by: current_user)
    support_case = window.case
    confirmation_message = <<~EOF.squish
      Maintenance of #{support_case.associated_model.name} confirmed by
      #{current_user.name}; this #{support_case.associated_model_type} is now
      under maintenance
    EOF
    support_case.add_rt_ticket_correspondence(confirmation_message)
    redirect_to cluster_path(window.case.cluster)
  end
end
