
# This controller exists so we have a common root controller which can be
# shared between our app and other Rails engines used by the app, in particular
# RailsAdmin. We can't just use ApplicationController for this as this contains
# common app-specific behaviour which we do not want shared.
class RootController < ActionController::Base
  include Clearance::Controller

  protect_from_forgery with: :exception

  before_action :set_sentry_raven_context

  private

  def set_sentry_raven_context
    if current_user
      Raven.user_context(
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        site: current_user.site&.name,
      )
    end
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
