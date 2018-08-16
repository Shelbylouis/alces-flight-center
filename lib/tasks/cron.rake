
namespace :alces do
  # NOTE: The crontab syntax required in production for running these tasks
  # should be documented in `docs/release-process.md`.
  namespace :cron do
    desc 'Tasks to run every minute'
    task every_minute: 'alces:maintenance_windows:progress'

    desc 'Tasks to run every hour'
    task hourly: nil

    desc 'Tasks to run at the start of every business day'
    task daily: 'alces:admin_mailer:daily_reminder'
  end
end
