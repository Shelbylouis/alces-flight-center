class AdminMailerPreview < ApplicationMailerPreview
  def daily_open_cases_list
    admin = Case.active.map(&:assignee).compact.uniq.sample

    AdminMailer.daily_open_cases_list(
       admin,
       admin.assigned_cases.active.prioritised
    )
  end
end
