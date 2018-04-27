
require_relative '../deployment'

namespace :alces do
  namespace :deploy do
    [:production, :staging].each do |deploy_type|
      desc "Deploy to #{deploy_type}"
      task deploy_type do
        deploy(deploy_type)
      end

      namespace deploy_type do
        desc "Output what will happen on deploy to #{deploy_type}, without doing anything"
        task :dry_run do
          deploy(deploy_type, dry_run: true)
        end
      end
    end

    namespace :production do
      desc "Deploy hotfix release to production"
      task :hotfix do
        deploy(:hotfix)
      end

      namespace :hotfix do
        desc 'Output what will happen on hotfix deploy to production, without doing anything'
        task :dry_run do
          deploy(:hotfix, dry_run: true)
        end
      end
    end

    def deploy(*args, **kwargs)
      Deployment.new(*args, **kwargs).deploy
    end
  end
end
