class ComponentExpansionsController < ApplicationController
  # Ensure actions authorize the resource they operate on (using Pundit).
  after_action :verify_authorized

  def index
    authorize ComponentExpansion
  end

  def edit
    authorize ComponentExpansion
  end

  def create
    expansion = @cluster_part.component_expansions
                             .new create_expansion_params
    authorize expansion
    if expansion.save
      msg = "Successfully added the: #{expansion.expansion_type.name}"
      flash[:success] = msg
    else
      expansion_errors.push expansion
      flash_errors 'Could not add the expansion'
    end
    redirect_back fallback_location: @cluster_part
  end

  def update
    @cluster_part.component_expansions.each do |expansion|
      authorize expansion
      new_params = update_expansion_params expansion
      unless expansion.update new_params
        expansion_errors.push expansion
      end
    end
    redirect_update
  end

  def destroy
    expansion = component_expansion_from_param
    authorize expansion
    if expansion.destroy
      flash[:success] = 'Successfully deleted expansion'
    else
      flash[:error] = 'Failed to delete expansion'
    end
    redirect_back fallback_location: '/'
  end

  private

  def redirect_update
    if expansion_errors.empty?
      flash[:success] = 'Successfully updated the expansions'
      redirect_to @cluster_part
    else
      flash_errors 'Errors updating expansions:'
      redirect_to edit_component_component_expansion_path(@cluster_part)
    end
  end

  def flash_errors(header)
    error_flash_models(expansion_errors, header) do |expansion|
      expansion.expansion_type.name
    end
  end

  def expansion_errors
    @errors_in_component_expansion_form_data ||= []
  end

  def create_expansion_params
    params.require(:component_expansion).permit([:slot, :ports]).tap do |x|
      type_id = params.require(:expansion_type).require(:id)
      x.merge!(expansion_type: ExpansionType.find_by_id(type_id))
    end
  end

  def update_expansion_params(expansion)
    id = expansion.id
    params.permit([:"slot#{id}", :"ports#{id}"]).to_h.map do |k, v|
      [k.to_s.chomp(id.to_s).to_sym, v]
    end.to_h
  end

  def component_expansion_from_param
    ComponentExpansion.find_by_id params.require(:id)
  end
end
