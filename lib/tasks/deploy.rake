
require_relative '../deployment'

namespace :alces do
  namespace :deploy do
    desc 'Deploy to production'
    task :production do
      deploy
    end

    namespace :production do
      desc 'Output what will happen on deploy to production, without doing anything'
      task :dry_run do
        deploy(dry_run: true)
      end
    end

    def deploy(**args)
      Deployment.new(**args).deploy
    end
  end
end
