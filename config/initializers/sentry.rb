
if ENV.has_key?('SENTRY_DSN')
  Raven.configure do |config|
    config.dsn = ENV.fetch('SENTRY_DSN')

    # Do not send any filtered parameters to Sentry.
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  end
end
