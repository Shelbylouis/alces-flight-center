require_relative 'boot'

require "rails"

# Include just the parts of Rails we use. Should be similar to
# https://github.com/rails/rails/blob/master/railties/lib/rails/all.rb, but
# without `active_storage`.
%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  action_cable/engine
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AlcesFlightCenter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Use our local time zone whenever we work with/display times in app; no
    # matter where users are we want to use and for them to see the schedule
    # that we operate on.
    config.time_zone = 'London'

    # Still save everything in UTC; should make things more straightforward if
    # we ever want to handle times in other time zones in future.
    config.active_record.default_timezone = :utc

    config.email_bcc_address = ENV['EMAIL_BCC_ADDRESS'] || 'tickets@alces-software.com'

    config.active_job.queue_adapter = :resque

    config.email_from = if ENV['STAGING']
                          'Alces Flight Center Staging <center+staging@alces-software.com>'
                        else
                          'Alces Flight Center <center@alces-software.com>'
                        end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
