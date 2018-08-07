class SentryJob < ActiveJob::Base
  queue_as :default

  def perform(event)
    Raven.send_event(event)
  end
end


if ENV.has_key?('SENTRY_DSN')
  Raven.configure do |config|
    config.dsn = ENV.fetch('SENTRY_DSN')

    # Do not send any filtered parameters to Sentry.
    config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

    config.async = lambda { |event|
      SentryJob.perform_later(event.to_hash)
    }
  end
end
