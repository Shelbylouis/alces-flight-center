class SsoSessionsController < Clearance::SessionsController
  # No need to do authorization in this controller, want to just let any User
  # access actions and Clearance appropriately handle things as normal.
  after_action :verify_authorized, only: []

  def url_after_destroy
    '/'
  end
end
