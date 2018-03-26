class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    @table_tile = 'All Components' # Consider removing
    @component_groups = component_groups_from_type
  end

  def show
    @subtitle = @component.component_type.name
  end

  private

  def component_groups_from_type
    if @scope.is_a? ComponentGroup
      [@scope]
    elsif type_param.blank?
      @scope.component_groups
    else
      @scope.component_groups_by_type.find do |group_type|
        group_type.name == type_param[:type]
      end.component_groups
    end
  end

  def type_param
    params.permit(:type)
  end
end
