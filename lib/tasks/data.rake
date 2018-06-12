
namespace :alces do
  namespace :data do
    desc <<~EOF.squish
      Import latest production database backup and then migrate this as will be
      done on next deploy
    EOF
    task import_and_migrate_production: [
      'alces:data:import_production',
      'db:migrate:with_data',
      'alces:data:obfuscate_users',
      'alces:data:create_sso_accounts',
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

    task obfuscate_users: :environment do
      User.all.each do |user|
        local_part = user.email.split('@').first
        new_email =  "#{local_part}@example.com"
        user.update!(email: new_email, password: 'password')
      end
    end

    desc <<~DESC
      For every Flight Center User, create a corresponding Flight SSO Account
      locally if this does not already exist
    DESC
    task create_sso_accounts: :environment do
      sso_repo = '../flight-sso'

      sso_temp_dir = File.join(sso_repo, 'tmp')
      mkdir_p sso_temp_dir

      Tempfile.create('', sso_temp_dir) do |sso_script|
        # Create script within flight-sso repo (so available within its Docker
        # container) to create all needed Accounts for Flight Center Users.
        sso_script.write(sso_account_creation_ruby)
        sso_script.close
        sso_script_path = "tmp/#{File.basename sso_script}"

        # Run the script within the flight-sso repo, in the flight-sso Docker
        # container.
        Dir.chdir(sso_repo) do
          sso_docker_command = <<~SH.squish
            sudo docker-compose run --rm sso bin/rails runner
            '#{sso_script_path}' --trace
          SH

          sh sso_docker_command
        end
      end
    end

    def sso_account_creation_ruby
      User.order(:created_at).map do |user|
        email_local_part = user.email.split('@').first
        new_account_username = email_local_part.gsub(/[^0-9a-z]/i, '')

        <<~RUBY.strip_heredoc
          if Account.find_by_username('#{new_account_username}') || Account.find_by_email('#{user.email}')
            puts "Skipping account #{new_account_username}"
          else
            puts "Creating account username: #{new_account_username}, email: #{user.email}"
            Account.create!(
              username: '#{new_account_username}',
              email: '#{user.email}',
              password: 'password',
              terms: true
            ).confirm
          end
        RUBY
      end.join("\n")
    end
  end
end
