class CaseCommentsController < ApplicationController
  def create
    my_case = Case.find_from_id!(params.require(:case_id))
    fallback_location = @scope.dashboard_case_path(my_case)

    new_comment = my_case.case_comments.create(
        user: current_user,
        text: params.require(:case_comment)
                  .permit(:text)
                  .require(:text)
    )

    if new_comment.persisted?
      flash[:notice] = 'New comment added.'
    else
      flash[:error] = "Your comment was not added. #{new_comment.errors.full_messages.join('; ').strip}"
    end

    redirect_back fallback_location: fallback_location

  rescue ActionController::ParameterMissing
    flash[:error] = 'Empty comments are not permitted.'
    redirect_back fallback_location: fallback_location
  end
end
