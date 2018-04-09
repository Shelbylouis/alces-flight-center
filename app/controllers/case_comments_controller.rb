class CaseCommentsController < ApplicationController
  before_action :require_login

  def create
    case_id = params[:id]
    my_case = Case.find(case_id)

    if my_case.site == current_user.site || current_user.admin?
      my_case.case_comments.create(user: current_user, text: params[:text])
      flash[:notice] = 'New comment added.'
    else
      flash[:error] = 'You do not have permission to comment on this case.'
    end

    redirect_to case_path(case_id)
  end
end
