class ComponentExpansionsController < ApplicationController
  def update
    @cluster_part.component_expansions.each do |expansion|
      update_expansion(expansion)
    end
    redirect_update
  end

  def edit
    @title = "Edit Expansions"
    @subtitle = @cluster_part.name
  end

  private

  def redirect_update
    if expansion_errors.empty?
      redirect_to @cluster_part
    else
      flash_update_error
      redirect_to edit_component_component_expansion_path(@cluster_part)
    end
  end

  def flash_update_error
    header = "Errors updating expansions:\n"
    flash[:error] = StringIO.new(header).tap do |io|
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

  def update_expansion(expansion)
    unless expansion.update(expansion_param(expansion))
      expansion_errors.push expansion
    end
  end

  def expansion_param(expansion)
    id = expansion.id
    raw_params = params.require([:"slot#{id}", :"ports#{id}"])
    {
      slot: raw_params[0],
      ports: raw_params[1]
    }
  end
end
