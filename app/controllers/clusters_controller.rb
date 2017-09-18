class ClustersController < ApplicationController
  
  def new
    @site = find_site
    @cluster = @site.clusters.build
  end

  private

  def find_site
    Site.find(params[:site_id])
  end
end
