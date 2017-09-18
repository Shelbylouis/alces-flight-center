class ComponentsController < ApplicationController

  def new
    @cluster = find_cluster
    @component = @cluster.components.build
  end

  private

  def find_cluster
    Cluster.find(params[:cluster_id])
  end

end
