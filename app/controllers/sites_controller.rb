class SitesController < ApplicationController
  def index
    @title = 'Alces Admin Sites Dashboard'
    @sites = Site.all
  end

  def show
    @title = "#{@site.name} Management Dashboard"
    @subtitle = "Welcome #{@site.name}"
  end
end
