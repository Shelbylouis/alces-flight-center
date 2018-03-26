class SitesController < ApplicationController
  def index
    @title = 'Alces Admin Sites Dashboard'
    @sites = Site.all
  end

  def show; end
end
