
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

    namespace :staging do
      task obfuscate_user_data: :environment do
        staging_password = ENV['STAGING_PASSWORD']
        unless staging_password
          raise <<~ERROR.squish
            STAGING_PASSWORD environment variable must be set, to be used as
            password for all Site contacts in staging environment
          ERROR
        end

        User.where(admin: false).each do |user|
          email_base = user.email.split('@').first
          new_email = "#{email_base}@alces-software.com"
          user.update!(email: new_email, password: staging_password)
        end
      end
    end

    def deploy(*args, **kwargs)
      Deployment.new(*args, **kwargs).deploy
    end
  end
end
