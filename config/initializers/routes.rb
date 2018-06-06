
Rails.application.routes.default_url_options[:protocol] = 'https' unless Rails.env.development?

# Use same host as configured for environment for mailers when generating URLs.
Rails.application.routes.default_url_options[:host] =
  Rails.application.config.action_mailer.default_url_options[:host]
