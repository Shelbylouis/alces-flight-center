class CaseCommentsController < ApplicationController
  def create
    my_case = Case.find_from_id!(params.require(:case_id))

    new_comment = my_case.case_comments.new(comment_params)

    if new_comment.save
      flash[:notice] = 'New comment added.'
    else
      flash[:error] = "Your comment was not added. #{new_comment.errors.full_messages.join('; ').strip}"
    end

    fallback_location = @scope.dashboard_case_path(my_case)
    redirect_back fallback_location: fallback_location
  end

  private

  def comment_params
    params.require(:case_comment)
      .permit(:text)
      .merge(user: current_user)
  end
end
