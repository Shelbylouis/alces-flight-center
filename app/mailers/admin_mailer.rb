class AdminMailer < ApplicationMailer

  def daily_open_cases_list(admin, cases)
    @admin = admin
    @cases = cases.decorate

    mail(
      to: admin.email,
      subject: 'Flight Center daily summary'
    )
  end

end
