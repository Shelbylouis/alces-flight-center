
require 'rake'

class Deployment
  include Rake::DSL

  def initialize(dry_run: false)
    @dry_run = dry_run
  end

  def deploy
    important 'Make sure you merge anything you want deployed to master!'

    run 'git checkout master'
    run 'git push origin'
    run 'git push production'

    run "ssh ubuntu@apps.alces-flight.com -- 'dokku --rm run flight-center rake db:migrate'"
    run "ssh ubuntu@apps.alces-flight.com -- 'dokku --rm run flight-center rake data:migrate'"

    today = Date.today.iso8601
    # today="$(date -I)-hotfix" # Uncomment for hotfix release. XXX handle this

    run 'git tag production master -f'
    run "git tag #{today} master"
    run 'git push --tags -f origin master'

    important "Don't forget to rename the 'Done' Trello list to '#{today}'!"
  end

  private

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

  def important(message)
    STDERR.puts "\n=== #{message} ===\n\n"
  end

  def info(message)
    STDERR.puts ">>> #{message}"
  end
end
