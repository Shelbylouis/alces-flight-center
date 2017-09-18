class ComponentsController < ApplicationController

  def show
    @component = Component.find(params[:id])
    @cluster = find_cluster(@component)
  end

  def new
    @cluster = find_cluster
    @component = @cluster.components.build
  end

  def create
    @cluster = find_cluster
    @component = @cluster.components.new(component_params)
    if @component.save
      redirect_to [@cluster, @component]
    else
      render 'new'
    end
  end

  private

  def find_cluster(component = nil)
    cluster_id = (component ? component.cluster.id : params[:cluster_id])
    Cluster.find(cluster_id)
  end

  def component_params
    params.require(:component).permit(:name, :description, :component_type)
  end
end
