class CaseMailer < ApplicationMailer
  def comment
    @comment = params[:comment]
    @case = @comment.case
    mail(
      cc: @case.cc_emails,
      subject: @case.email_subject,
    )
  end
end
