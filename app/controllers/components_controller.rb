class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    define_variables_from_type
  end

  def import
    # @scope here is our cluster
    authorize @scope, :import_components?
    importer = BenchwareImporter.new(@scope)

    uploaded_file = params[:benchdown]
    new_comps, updated_comps, invalid_comps = importer.from_file(uploaded_file)

    if invalid_comps.empty?
      flash[:success] = success_message(new_comps, updated_comps)
    else
      flash[:alert] = warning_message(new_comps, updated_comps, invalid_comps)
    end
    redirect_to cluster_components_path(@scope)
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

  def success_message(new_comps, updated_comps)
    "Imported #{view_context.pluralize(new_comps, 'new component')} and updated #{view_context.pluralize(updated_comps, 'existing component')}"
  end

  def warning_message(new_comps, updated_comps, invalid_comps)
    "The following components were not imported: #{invalid_comps.join(', ')}. #{new_comps} new and #{updated_comps} updated components were processed successfully."
  end
end
