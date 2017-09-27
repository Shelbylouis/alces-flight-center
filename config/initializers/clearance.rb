Clearance.configure do |config|
  config.mailer_sender = "reply@example.com" # XXX change
  config.rotate_csrf_on_sign_in = true
  config.allow_sign_up = false
end
