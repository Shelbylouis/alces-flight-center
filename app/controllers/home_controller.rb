class HomeController < ApplicationController
  def index
    @title = "#{current_site.name} Management Dashboard"
    @subtitle = "Welcome #{current_user.name}"

    @site = current_site
  end
end
