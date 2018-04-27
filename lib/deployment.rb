
require 'rake'

class Deployment
  include Rake::DSL

  def initialize(type, dry_run: false)
    @remote, @tag = parse_deploy_type(type)
    @dry_run = dry_run
  end

  def deploy
    important 'Make sure you merge anything you want deployed to master!'

    unless dry_run?
      STDERR.puts "About to deploy to real #{remote} environment, are you sure? [y/n]"
      input = STDIN.gets.chomp
      abort unless input.downcase == 'y'
    end

    run 'git checkout master'
    run 'git push origin'
    run "git push -f #{remote}"

    dokku_run 'rake db:migrate', app: app_name
    dokku_run 'rake data:migrate', app: app_name

    run "git tag #{remote} master -f"
    run "git tag #{tag} master"
    run 'git push --tags -f origin master'

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

  def dokku_run(command, app:)
    run "ssh ubuntu@apps.alces-flight.com -- 'dokku --rm run #{app} #{command}'"
  end

  def run(*args)
    if dry_run?
      info(args.join(' '))
    else
      sh(*args)
    end
  end

  def dry_run?
    @dry_run
  end

  def app_name
    case remote
    when :production
      'flight-center'
    when :staging
      'flight-center-staging'
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