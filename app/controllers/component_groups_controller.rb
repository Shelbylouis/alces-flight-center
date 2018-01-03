class ComponentGroupsController < ApplicationController
  decorates_assigned :component_group

  def show
    @component_group = ComponentGroup.find(params[:id])
    @title = "#{@component_group.name} Management Dashboard"
    @subtitle = "#{@component_group.component_type.name} Group"
  end
end
