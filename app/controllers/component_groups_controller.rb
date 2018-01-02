class ComponentGroupsController < ApplicationController
  decorates_assigned :component_group

  def show
    @component_group = ComponentGroup.find(params[:id])
  end
end
