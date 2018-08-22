class AdminMailer < ApplicationMailer

  def daily_open_cases_list(admin, cases)
    @admin = admin
    @cases = cases.decorate

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

end
