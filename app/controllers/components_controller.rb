class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
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
      @scope.component_groups.joins(:component_type).order('ordering')
    else
      @scope.component_groups.joins(:component_type).order('ordering')
        .where({ component_types: { name: type_param[:type] } })
    end
  end

  def type_param
    params.permit(:type)
  end
end
