class ChangeMotdRequestsController < ApplicationController
  def apply
    change_motd_request = ChangeMotdRequest.find(params[:id])
    change_motd_request.apply!(current_user)
    redirect_back fallback_location: change_motd_request.case
    flash[:success] = 'The cluster has been updated to reflect this change.'
  end
end
