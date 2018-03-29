Clearance.configure do |config|
  config.routes = false
  config.mailer_sender = 'support@alces-flight.com'
  config.rotate_csrf_on_sign_in = true
  config.allow_sign_up = false
  config.cookie_name = 'flight_sso'
end

# Monkey-patch Clearance::Session to use JWT token for auth.
#
# Note: we don't want to overwrite the Flight SSO cookie in development or production, but since some of our tests
# log users in and perform page navigation, we need a way of persisting that - hence the tests for Rails.env.test?
# below.

require 'clearance/session'

class Clearance::Session
  def add_cookie_to_headers(headers)
    # Don't try to overwrite the Flight SSO cookie, unless we're under test
    if cookie_value[:value].present? && Rails.env.test?
      Rack::Utils.set_cookie_header!(
          headers,
          remember_token_cookie,
          cookie_value
      )
    end
  end

  def user_from_remember_token(token)
    ::User.from_jwt_token(token)
  end

  def sign_in(user, &block)
    @current_user = user
    status = run_sign_in_stack

    if status.success?
      # NO! Don't overwrite the SSO token! (Unless we're under test)
      if Rails.env.test?
        cookies[remember_token_cookie] = user && user.remember_token
      end
    else
      @current_user = nil
    end

    if block_given?
      block.call(status)
    end
  end

  def sign_out
    @current_user = nil
    # Don't delete the SSO cookie here - it will fail since doing so needs an explicit domain
  end
end
