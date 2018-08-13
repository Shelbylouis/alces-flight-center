require 'slack-notifier'
class CaseMailer < ApplicationMailer

  layout 'case_mailer'

  default bcc: Rails.application.config.email_bcc_address

  def new_case(my_case)
    @case = my_case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @case.user.email }, # Exclude the user raising the case
      subject: @case.email_subject
    )
    SlackNotifier.case_notification(@case)
  end

  def change_assignee_id(my_case, old_id, new_id)
    @case = my_case
    @assignee = new_id.nil? ? nil : User.find(new_id)
    mail(
      cc: @assignee&.email, # Send to new assignee only
      subject: @case.email_reply_subject
    )
    SlackNotifier.assignee_notification(@case, @assignee)
  end

  def change_subject(my_case, old_val, new_val)
    @case = my_case
    @old = old_val
    @new = new_val
    mail(
      cc: @case.email_recipients,
      subject: @case.email_reply_subject
    )
  end

  def change_issue_id(my_case, old_val, new_val)
    @case = my_case
    @old = Issue.find(old_val).decorate.label_text
    @new = Issue.find(new_val).decorate.label_text
    mail(
      cc: @case.email_recipients,
      subject: @case.email_reply_subject
    )
  end

  def comment(comment)
    @comment = comment
    @case = @comment.case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @comment.user.email }, # Exclude the user making the comment
      subject: @case.email_reply_subject,
    )
    SlackNotifier.comment_notification(@case, @comment)
  end

  def maintenance_state_transition(my_case, text)
    @case = my_case
    @text = text
    mail(
      cc: @case.email_recipients,
      subject: @case.email_reply_subject
    )
    SlackNotifier.maintenance_state_transition_notification(@case, @text)
  end

  def maintenance_ending_soon(window, text)
    @case = window.case
    @text = text
    admin_emails = User.admins.map(&:email)

    mail(
      cc: admin_emails,
      subject: @case.email_reply_subject
    )
    SlackNotifier.maintenance_ending_soon_notification(@case, @text)
    window.set_maintenance_ending_soon_email_flag
  end

  def change_request(my_case, text, user)
    @case = my_case
    @text = text
    mail(
      cc: @case.email_recipients,
      subject: @case.email_reply_subject
    )
    SlackNotifier.change_request_notification(@case, @text, user)
  end
end
