
# This controller exists so we have a common root controller which can be
# shared between our app and other Rails engines used by the app, in particular
# RailsAdmin. We can't just use ApplicationController for this as this contains
# common app-specific behaviour which we do not want shared.
class RootController < ActionController::Base
  include Clearance::Controller

  protect_from_forgery with: :exception
end
