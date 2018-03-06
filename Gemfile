# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'aws-sdk-s3'
gem 'clearance'
gem 'http'
gem 'kramdown'
gem 'rails_admin', '~> 1.3'
gem 'rails_email_preview', '~> 2.0.4'
gem 'validates_email_format_of'
gem 'webpacker', '~> 3.0'
gem 'draper'
gem 'rails-data-migrations'
gem 'font-awesome-rails'
gem 'request_store'
gem 'bootsnap', require: false
gem "sentry-raven"
gem 'state_machines-activerecord'
gem 'state_machines-audit_trail'

gem 'bootstrap', '~> 4.0.0'
gem 'jquery-rails' # Required for Bootstrap.

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

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
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
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
