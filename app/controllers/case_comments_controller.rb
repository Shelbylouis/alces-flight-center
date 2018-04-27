class CaseCommentsController < ApplicationController
  before_action :require_login

  def create
    case_id = params[:case_id]
    my_case = Case.find(case_id)

    new_comment = my_case.case_comments.create(user: current_user, text: params[:case_comment][:text])
    if new_comment.persisted?
      flash[:notice] = 'New comment added.'
    else
      flash[:error] = "Your comment was not added. #{new_comment.errors.full_messages.join('; ').strip}"
    end

    redirect_to case_path(case_id)
  end
end