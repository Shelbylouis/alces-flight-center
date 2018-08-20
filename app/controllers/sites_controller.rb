class SitesController < ApplicationController

  after_action :verify_authorized, except: :home

  def index
    @sites = Site.all
  end
end
