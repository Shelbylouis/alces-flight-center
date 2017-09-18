class ComponentsController < ApplicationController

  def show
    @component = Component.find(params[:id])
    @cluster = find_cluster(@component)
  end

  def new
    @cluster = find_cluster
    @component = @cluster.components.build
  end

  def edit
    @component = Component.find(params[:id])
    @cluster = find_cluster(@component)
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

  def update
    @component = Component.find(params[:id])
    @cluster = find_cluster(@component)
    if @component.update(component_params)
      redirect_to [@cluster, @component]
    else
      render 'edit'
    end
  end

  def destroy
    @component = Component.find(params[:id])
    @cluster = find_cluster(@component)
    @component.destroy
    redirect_to @cluster
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
