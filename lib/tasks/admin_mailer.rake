namespace :alces do
  namespace :admin_mailer do
    desc 'Daily reminder email'
    task daily_reminder: :environment do
      ::DailyAdminReminder.process
    end
  end
end
