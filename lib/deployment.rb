
require 'rake'

class Deployment
  include Rake::DSL

  def initialize(type, dry_run: false)
    @remote, @tag = parse_deploy_type(type)
    @dry_run = dry_run
  end

  def deploy
    if production? && !current_branch.master?
      abort 'Must be on `master` branch to deploy to production!'
    end

    important 'Make sure you have anything you want deployed on this branch!'

    unless dry_run?
      STDERR.puts <<~EOF.squish
        About to deploy `#{current_branch}` branch to real #{remote}
        environment, are you sure? [y/n]
      EOF

      input = STDIN.gets.chomp
      abort unless input.downcase == 'y'
    end

    import_production_backup_to_staging if staging?

    run 'git push origin'
    run "git push #{remote} -f HEAD:master"

    dokku_run 'rake db:migrate', app: app_name
    dokku_run 'rake data:migrate', app: app_name

    run "git tag #{remote} -f"
    run "git tag #{tag}"
    run 'git push --tags -f origin'

    important <<~EOF.squish
      Don't forget to move all Trello cards included in this release to a
      '#{tag}' list!
    EOF
  end

  module Staging
    STAGING_PASSWORD = 'STAGING_PASSWORD'

    def self.password
      ENV.fetch(STAGING_PASSWORD)
    rescue KeyError
      raise <<~ERROR.squish
        #{STAGING_PASSWORD} environment variable must be set, to be used as
        password for all Site contacts in staging environment
      ERROR
    end
  end

  private

  attr_reader :remote, :tag

  PRODUCTION_APP = 'flight-center'
  STAGING_APP = 'flight-center-staging'

  def parse_deploy_type(type)
    case type
    when :production
      [:production, today]
    when :hotfix
      [:production, "#{today}-hotfix"]
    when :staging
      [:staging, "#{today}-staging"]
    else
      raise "Unknown deployment type: '#{type}'"
    end
  end

  def today
    Date.today.iso8601
  end

  def current_branch
    `git rev-parse --abbrev-ref HEAD`.strip.inquiry
  end

  def import_production_backup_to_staging
    # Get staging password first so we fail before doing anything if this
    # hasn't been given.
    staging_password = Staging.password

    staging_database_url = dokku_config_get('DATABASE_URL', app: STAGING_APP)
    database_server_url = File.dirname(staging_database_url)

    # Drop existing and then recreate empty staging database; need to stop app
    # container first so no open connections to database (which would cause
    # this to fail).
    dokku_stop STAGING_APP
    drop_database_command =
      "psql -d #{database_server_url} -c 'drop database \"#{STAGING_APP}\"'"
    run drop_database_command
    dokku_run 'rake db:create', app: STAGING_APP

    # Determine, download, and then import latest production backup to new
    # staging database.
    production_backup_file = `#{'bin/retrieve-production-backup'}`
    run "psql -d #{staging_database_url} -f #{production_backup_file}"

    # Obfuscate the imported production data for non-admin users to not use
    # real emails and to all use password passed as environment variable.
    obfuscate_dokku_command = <<~COMMAND.squish
      rake alces:deploy:staging:obfuscate_user_data
      STAGING_PASSWORD="#{Shellwords.escape(staging_password)}"
    COMMAND
    dokku_run obfuscate_dokku_command, app: STAGING_APP
  end

  def dokku_run(command, app:)
    run dokku_command("--rm run #{app} #{command}")
  end

  def dokku_config_get(env_var, app:)
    command = dokku_command("config:get #{app} #{env_var}")
    `#{command}`
  end

  def dokku_stop(app)
    run dokku_command("ps:stop #{app}")
  end

  def dokku_command(args)
    "ssh ubuntu@apps.alces-flight.com -- 'dokku #{args}'"
  end

  def run(*args)
    if dry_run?
      info(args.join(' '))
    else
      sh(*args)
    end
  end

  def production?
    remote == :production
  end

  def staging?
    remote == :staging
  end

  def dry_run?
    @dry_run
  end

  def app_name
    case remote
    when :production
      PRODUCTION_APP
    when :staging
      STAGING_APP
    else
      raise "Don't know how to handle remote: '#{remote}'"
    end
  end

  def important(message)
    STDERR.puts "\n=== #{message} ===\n\n"
  end

  def info(message)
    STDERR.puts ">>> #{message}"
  end
end
