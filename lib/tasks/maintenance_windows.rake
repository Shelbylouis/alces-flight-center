
namespace :alces do
  namespace :maintenance_windows do
    desc 'Progress each unfinished maintenance window to next needed state'
    task progress: :environment do |task|
      logger = create_logger('log/tasks/maintenance_windows/progress.log')
      logger.info("#{task.name} running at #{DateTime.current.iso8601}")

      MaintenanceWindow.unfinished.each do |window|
        message = ProgressMaintenanceWindow.new(window).progress
        logger.info(message)
      end
    end

    private

    def create_logger(log_path)
      FileUtils.mkdir_p(File.dirname(log_path))
      ActiveSupport::Logger.new(log_path)
    end
  end
end
