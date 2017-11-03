class ComponentsController < ApplicationController
  def show
    @component = Component.find(params[:id])
    @title = "#{@component.name} Management Dashboard"
    @subtitle = @component.component_type.name
  end
end
