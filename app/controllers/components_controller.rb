class ComponentsController < ApplicationController
  decorates_assigned :component

  def show
    @title = "#{@component.name} Management Dashboard"
    @subtitle = @component.component_type.name
  end
end
