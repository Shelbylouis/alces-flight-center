Clearance.configure do |config|
  config.routes = false
  config.mailer_sender = 'support@alces-flight.com'
  config.rotate_csrf_on_sign_in = true
  config.allow_sign_up = false
end
