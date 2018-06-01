class SsoSessionsController < Clearance::SessionsController
  def url_after_destroy
    '/'
  end
end
