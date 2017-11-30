
Rails.application.routes.default_url_options[:protocol] = 'https' unless Rails.env.development?
Rails.application.routes.default_url_options[:host] = 'center.alces-flight.com'
