class AdminMailer < ApplicationMailer
  default to: Rails.application.config.email_bcc_address

  def daily_open_cases_list(admin, case_ids)
    @admin = admin
    @cases = case_ids.map { |id| Case.find(id).decorate }

    mail(
      to: admin.email,
      subject: 'Flight Center daily summary'
    )
  end

  def new_log(log)
    @log = log
    @text = "New log created on #{@log.cluster.name}" \
      " #{@log&.component ? 'for ' + @log.component.name : nil }"

    mail( subject: "[Alces Flight Center] New log on #{@log.cluster.name}" )
    SlackNotifier.log_notification(@log, @text)
  end

  def cluster_check_submission(cluster, user)
    @cluster = cluster
    @user = user
    @text = "The daily checks for #{@cluster.name} have been submitted by #{@user.name}."\
      "\n#{@cluster.decorate.no_of_checks_passed}/#{@cluster.cluster_checks.count} checks passed"
    mail( subject: "[#{@cluster.name}] Daily cluster checks submitted" )
    SlackNotifier.cluster_check_submission_notification(@cluster, @user, @text)
  end

end
