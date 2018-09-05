class SitesController < ApplicationController
  def index
    # TODO remove order call when it's redundant (see Site#default_scope)
    @sites = Site.all.order(:identifier)
  end
end
