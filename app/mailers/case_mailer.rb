class CaseMailer < ApplicationMailer
  def comment
    @comment = params[:comment]
    @case = @comment.case
    mail(
      cc: @comment.email_recipients,
      subject: @case.email_subject,
    )
  end
end
