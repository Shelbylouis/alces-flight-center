class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    @title = 'Components'
    @components = @scope.components
    @table_tile = 'All Components' # Consider removing
  end

  def show
    @title = "#{@component.name} Management Dashboard"
    @subtitle = @component.component_type.name
  end
end
