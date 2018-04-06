
namespace :alces do
  namespace :cases do
    desc 'Archive cases that were resolved at least two weeks ago'
    task auto_archive: :environment do |task|
      logger = create_logger('log/tasks/cases/auto_archive.log')
      logger.info("#{task.name} running at #{DateTime.current.iso8601}")
      logger.info("Automatically archiving cases completed on or before #{2.weeks.ago}")

      Case.where(archived: false).each do |c|
        c.update_ticket_status!

        if c.ticket_completed? && c.completed_at && c.completed_at <= 2.weeks.ago
          c.archived = true
          logger.info("Archiving case #{c.id} completed at #{c.completed_at}")
        end
        c.save!
      end
    end

    private

    def create_logger(log_path)
      FileUtils.mkdir_p(File.dirname(log_path))
      shift_age = 'weekly'
      ActiveSupport::Logger.new(log_path, shift_age)
    end
  end
end
