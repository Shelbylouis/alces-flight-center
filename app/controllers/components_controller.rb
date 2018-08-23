class ComponentsController < ApplicationController
  decorates_assigned :component

  def index
    @component_groups = component_groups
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

  def component_groups
    if @scope.is_a? ComponentGroup
      [@scope]
    else
      @scope.component_groups
    end
  end

  def success_message(new_comps, updated_comps)
    "Imported #{view_context.pluralize(new_comps, 'new component')} and updated #{view_context.pluralize(updated_comps, 'existing component')}"
  end

  def warning_message(new_comps, updated_comps, invalid_comps)
    "The following components were not imported: #{invalid_comps.join(', ')}. #{new_comps} new and #{updated_comps} updated components were processed successfully."
  end
end
