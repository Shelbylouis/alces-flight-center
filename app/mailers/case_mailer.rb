class CaseMailer < ApplicationMailer

  default bcc: Rails.application.config.email_bcc_address

  def new_case
    @case = params[:case]
    mail(
      cc: @case.email_recipients,
      subject: @case.rt_ticket_subject
    )
  end

  def comment
    @comment = params[:comment]
    @case = @comment.case
    mail(
      cc: @comment.email_recipients,
      subject: @case.email_subject,
    )
  end

  def maintenance
    @case = params[:case]
    @text = params[:text]
    mail(
      cc: @case.email_recipients,
      subject: @case.email_subject
    )
  end
end
