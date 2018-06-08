# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read(File.join(File.dirname(__FILE__), '.ruby-version')).chomp

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

gem 'aws-sdk-s3'
gem 'clearance'
gem 'http'
gem 'kramdown'
gem 'rails_admin', '~> 1.3'
gem 'rails_email_preview', '~> 2.0.4'
gem 'validates_email_format_of'
gem 'webpacker', '~> 3.0'
gem 'draper'
gem 'data_migrate'
gem 'font-awesome-rails'
gem 'request_store'
gem 'bootsnap', require: false
gem "sentry-raven"
# Temporarily installed from GitHub as has been updated for Rails 5.2 (see
# https://github.com/state-machines/state_machines-activerecord/pull/71) but
# this is not yet in a tagged release.
gem 'state_machines-activerecord',
  github: 'state-machines/state_machines-activerecord',
  ref: 'fed06d9fa64af1cba49d241f4a3ae79626946fe3'
gem 'state_machines-audit_trail'
gem 'business_time'
gem "audited", "~> 4.7"
gem 'jwt'
gem 'pundit'

gem 'bootstrap', '~> 4.0.0'
gem 'jquery-rails' # Required for Bootstrap.

# Turbolinks makes navigating your web application faster. Read more:
# https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# For pretty emails
gem 'roadie-rails'
gem 'sass'

# For async emails
gem 'resque'
gem 'resque_mailer'
gem 'resque-sentry' # For Sentry integration; must be after `gem 'resque'`.

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'

  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'vcr'
  gem 'webmock'
end

group :test do
  gem 'email_spec'
  gem 'rails-controller-testing'
  gem 'shoulda-matchers'
  gem 'rspec-retry'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %>
  # anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'pry-rails'

  gem 'development_ribbon'

  # Checks corresponding database constraint exists for all model presence
  # validations. Run using `bin/generate-needed-null-constraint-migrations`
  # script.
  gem 'nullalign'

  # Detects various problems in database. Run with `active_record_doctor:*`
  # Rake tasks.
  gem 'active_record_doctor'

  # Regenerate state machine graphs using `rake
  # alces:generate:state_machine_diagrams`.
  gem 'state_machines-graphviz'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'slack-notifier'
