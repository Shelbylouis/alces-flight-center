class ComponentGroupsController < ApplicationController
  def show
    @component_group = ComponentGroup.find(params[:id])
  end
end
