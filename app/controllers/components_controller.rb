class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    define_variables_from_type
  end

  def import
    # @scope here is our cluster
    authorize @scope, :import_components?
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
      all_groups
    else
      all_groups.select { |cg| cg.component_type == type_param[:type] }
    end
  end

  def type_param
    params.permit(:type)
  end

  def all_groups
    @scope.component_groups
  end
end
