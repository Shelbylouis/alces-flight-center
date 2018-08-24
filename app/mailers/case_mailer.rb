require 'slack-notifier'
class CaseMailer < ApplicationMailer

  layout 'case_mailer'

  default bcc: Rails.application.config.email_bcc_address

  def new_case(my_case)
    @case = my_case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @case.user.email }, # Exclude the user raising the case
      subject: @case.email_subject,
      bypass_timestamp_update: true
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
    SlackNotifier.subject_notification(@case, @old, @new)
  end

  def change_issue_id(my_case, old_val, new_val)
    @case = my_case
    @old = Issue.find(old_val).decorate.label_text
    @new = Issue.find(new_val).decorate.label_text
    mail(
      subject: @case.email_reply_subject
    )
    SlackNotifier.issue_notification(@case, @old, @new)
  end

  def comment(comment)
    @comment = comment
    @case = @comment.case
    mail(
      cc: @case.email_recipients.reject { |contact| contact == @comment.user.email }, # Exclude the user making the comment
      subject: @case.email_reply_subject,
      bypass_timestamp_update: !comment.user.admin?  # Only count admin comments towards update time
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

  def change_request(my_case, text, user, recipients)
    @case = my_case
    @text = text
    mail(
      cc: recipients,
      subject: @case.email_reply_subject
    )
    SlackNotifier.change_request_notification(@case, @text, user)
  end

  def change_association(my_case, user)
    @case = my_case
    reference_texts = @case.associations
      .map { |a| a.decorate.reference_text }
    if reference_texts.empty?
      @text = 'This case no longer has any associated components.'
    else
    @text = %{Changed the affected components on this case to:

• #{reference_texts.join("\n • ")}
    }
    end

    mail( subject: @case.email_reply_subject )
    SlackNotifier.case_association_notification(@case, user, @text)
  end

  def resolve_case(kase, user)
    @case = kase
    @user = user
    @text = "#{@case.display_id} has been resolved by #{@user.name} and is awaiting closure"

    mail( subject: @case.email_reply_subject )
    SlackNotifier.resolved_case_notification(@case, @user, @text)
  end

  private

  def mail(**options)
    super(options)
    return if options[:bypass_timestamp_update]
    all_recipients = [options[:cc], options[:to]].flatten.compact
    # This is a bit of a hack - since we'd need to check each User model for
    # admin-ness to be fully correct - but that would be quite costly!
    # In practice checking for '@alces-' is enough since all admins are @alces
    # and even if we had non-alces admins, emailing them probably counts as
    # an email update to the customer.
    has_non_admin = !all_recipients.reject { |a| a.include? '@alces-' }.empty?
    if has_non_admin && @case
      @case.update_columns(last_update: Time.now)
    end
  end
end
