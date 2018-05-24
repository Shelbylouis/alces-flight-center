
namespace :alces do
  namespace :data do
    desc <<~EOF.squish
      Import latest production database backup and then migrate this as will be
      done on next deploy
    EOF
    task import_and_migrate_production: [
      'alces:data:import_production',
      'db:migrate',
      'data:migrate',
    ]

    desc <<~EOF.squish
      Import latest production database backup from S3 as new development
      database, with emails and passwords modified
    EOF
    task :import_production do
      # Delegate out to the shell script which does all the work.
      unless system('bin/import-production-data')
        abort 'Production data import failed!'
      end
    end
  end
end
