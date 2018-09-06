class DailyAdminReminder
  class << self

    def process
      User.admins.each do |admin|
        cases = admin.assigned_cases.active.prioritised

        unless cases.empty?
          AdminMailer.daily_open_cases_list(admin, cases.map(&:id)).deliver_later
        end
      end
    end

  end
end
