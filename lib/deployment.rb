
require 'rake'
require 'erb'

class Deployment
  include Rake::DSL

  VERSION_ENV_VAR = 'FC_VERSION'.freeze

  def initialize(type,dry_run: false)
    abort "Must set ENV['#{VERSION_ENV_VAR}'] within command!" unless ENV.include?(VERSION_ENV_VAR)
    @remote = type
    @dry_run = dry_run
    @tag = ENV[VERSION_ENV_VAR]

  end

  def deploy
    if production? && !current_branch.master? && !dry_run?
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

    dokku_config_set(VERSION_ENV_VAR, tag, app: app_name, restart: false)
    run "git push #{remote} -f #{current_branch}:master"

    import_production_backup_to_staging if staging?

    run "git tag -f #{remote} #{current_branch}"
    run "git tag -f #{tag} #{current_branch}"
    run "git push --tags -f origin #{current_branch}"

    scp_database_backup_script

    output_manual_steps
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

  def current_branch
    @current_branch ||= `git rev-parse --abbrev-ref HEAD`.strip.inquiry
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
      "psql -d #{database_server_url} -c 'drop database if exists \"#{STAGING_APP}\"'"
    run drop_database_command
    dokku_run 'rake db:create', app: STAGING_APP

    # Determine, download, and then import latest production backup to new
    # staging database.
    production_backup_file = `#{'bin/retrieve-production-backup'}`
    run "psql -d #{staging_database_url} -f #{production_backup_file}"

    # Run migrations since last deploy to production; needs to occur after
    # production import and before obfuscating imported Users (to ensure
    # running this task with migrated database).
    dokku_run 'rake db:migrate:with_data', app: STAGING_APP

    # Obfuscate the imported production data for non-admin users to not use
    # real emails and to all use password passed as environment variable.
    obfuscate_dokku_command = <<~COMMAND.squish
      rake alces:deploy:staging:obfuscate_users
      STAGING_PASSWORD="#{Shellwords.escape(staging_password)}"
    COMMAND
    dokku_run obfuscate_dokku_command, app: STAGING_APP

    dokku_start STAGING_APP
  end

  def scp_database_backup_script
    # Staging database is just imported and migrated production backup, so
    # don't need to install this script (and don't want to, in case it has
    # changed and we do not want the changes running in production yet)
    return unless production?

    command = <<~COMMAND.squish
      scp bin/backup-database
      ubuntu@apps.alces-flight.com:/home/ubuntu/flight-center-backup-database
    COMMAND
    sh command
  end

  def output_manual_steps
    manual_steps = [
      [
        <<~EOF.squish,
          Ensure shared production server `crontab` for user log in as (currently
          `ubuntu`) includes the following section:
        EOF
        <<~EOF.strip_heredoc,
        ```
        #{crontab}
        ```
        EOF
      ].join("\n\n"),
      <<~EOF.squish,
        Move all Trello cards for things included in this release to a '#{tag}'
        column at https://trello.com/b/EYQnm3F9/alces-flight-center.
      EOF
      <<~EOF.squish
        Announce the release at https://alces.slack.com/messages/C72GT476Y/,
        mentioning where to see what's in this release (the new '#{tag}'
        column).
      EOF
    ]

    important <<~EOF.squish
      You're not done yet! The following manual steps are still required
    EOF
    manual_steps.each_with_index do |step, index|
      formatted_step = "#{index + 1}. #{step}"
      puts formatted_step
    end
  end

  def crontab
    variables = { remote: remote, app_name: app_name }
    render_erb(crontab_template, variables)
  end

  def crontab_template
    current_dir = File.expand_path(File.dirname(__FILE__))
    File.read(File.join(current_dir, 'deployment/crontab.erb'))
  end

  def render_erb(template, variables)
    safe_level = 0
    trim_mode = '-'
    ERB.new(template, safe_level, trim_mode).result(
      OpenStruct.new(variables).instance_eval { binding }
    )
  end

  def dokku_run(command, app:)
    run dokku_command("--rm run #{app} #{command}")
  end

  def dokku_config_get(env_var, app:)
    command = dokku_command("config:get #{app} #{env_var}")
    `#{command}`.strip
  end

  def dokku_config_set(key, value, app:, restart: true)
    run dokku_command("config:set #{restart ? '' : '--no-restart'} #{app} #{key}=#{value}")
  end

  def dokku_stop(app)
    run dokku_command("ps:stop #{app}")
  end

  def dokku_start(app)
    run dokku_command("ps:start #{app}")
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
