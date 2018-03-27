class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    @table_tile = 'All Components' # Consider removing
    define_variables_from_type
  end

  private

  def define_variables_from_type
    @component_groups = component_groups_from_type
    @type = parse_type
  end

  def parse_type
    raw = type_param[:type]
    raw.present? ? raw : 'All'
  end

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
