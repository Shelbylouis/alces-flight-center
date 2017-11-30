class ComponentsController < ApplicationController
  decorates_assigned :component

  def show
    @component = Component.find(params[:id])
    @title = "#{@component.name} Management Dashboard"
    @subtitle = @component.component_type.name
  end
end
