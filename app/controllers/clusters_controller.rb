class ClustersController < ApplicationController
  def index
    @site = find_site
    @clusters = @site.clusters.all
  end

  def show
    @cluster = Cluster.find(params[:id])
    @site = find_site(@cluster)
  end

  def new
    @site = find_site
    @cluster = @site.clusters.build
  end

  def edit
    @cluster = Cluster.find(params[:id])
    @site = find_site(@cluster)
  end

  def create
    @site = find_site
    @cluster = @site.clusters.new(cluster_params)
    if @cluster.save
      redirect_to [@site, @cluster]
    else
      render 'new'
    end
  end

  def update
    @cluster = Cluster.find(params[:id])
    @site = find_site(@cluster)
    if @cluster.update(cluster_params)
      redirect_to [@site, @cluster]
    else
      render 'edit'
    end
  end

  def destroy
    @cluster = Cluster.find(params[:id])
    @site = find_site(@cluster)
    @cluster.destroy
    redirect_to @site
  end

  private

  def find_site(cluster = nil)
    site_id = (cluster ? cluster.site.id : params[:site_id])
    Site.find(site_id)
  end

  def cluster_params
    params.require(:cluster).permit(:name, :description, :support_type)
  end
end
