
namespace :alces do
  namespace :cron do
    desc 'Tasks to run every minute'
    task every_minute: 'alces:maintenance_windows:progress'
  end
end
