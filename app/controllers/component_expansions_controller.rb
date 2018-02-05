class ComponentExpansionsController < ApplicationController
  def create
    expansion = @cluster_part.component_expansions
                             .create create_expansion_param
    if expansion.valid?
      msg = "Successfully added the: #{expansion.expansion_type.name}"
      flash[:success] = msg
    else
      expansion_errors.push expansion
      flash_error 'Could not add the component'
    end
    redirect_back fallback_location: @cluster_part
  end

  def edit
    @title = "Edit Expansions"
    @subtitle = @cluster_part.name
  end

  def update
    @cluster_part.component_expansions.each do |expansion|
      new_params = update_expansion_param expansion
      unless expansion.update new_params
        expansion_errors.push expansion
      end
    end
    redirect_update
  end

  def destroy
    if component_expansion_param.destroy
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
      flash_error 'Errors updating expansions:'
      redirect_to edit_component_component_expansion_path(@cluster_part)
    end
  end

  def flash_error(header)
    flash[:error] = StringIO.new(header + "\n").tap do |io|
      io.read
      expansion_errors.each do |expansion|
        io.puts "#{expansion.expansion_type.name}: #{expansion.errors.full_messages}"
      end
      io.rewind
    end.read
  end

  def expansion_errors
    @errors_in_component_expansion_form_data ||= []
  end

  def create_expansion_param
    params.require(:component_expansion).permit([:slot, :ports]).tap do |x|
      type_id = params.require(:expansion_type).require(:id)
      x.merge!(expansion_type: ExpansionType.find_by_id(type_id))
    end
  end

  def update_expansion_param(expansion)
    id = expansion.id
    params.permit([:"slot#{id}", :"ports#{id}"]).to_h.map do |k, v|
      [k.to_s.chomp(id.to_s).to_sym, v]
    end.to_h
  end

  def component_expansion_param
    ComponentExpansion.find_by_id params.require(:id)
  end
end
