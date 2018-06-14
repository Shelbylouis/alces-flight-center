class ErrorsController < ApplicationController

  # Neither of these should require authorization.
  after_action :verify_authorized, except: NO_AUTH_ACTIONS + [:not_found, :internal_server_error]

  def not_found
    @title = 'Page not found'
    render(status: 404)
  end

  def internal_server_error
    @title = 'An error has occurred'
    render(status: 500)
  end
end
