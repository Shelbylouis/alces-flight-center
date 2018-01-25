class ComponentExpansionsController < ApplicationController
  def update
    @cluster_part.component_expansions.each do |expansion|
      update_expansion(expansion)
    end
    redirect_to @cluster_part
  end

  def edit
    @title = "Edit Expansions"
    @subtitle = @cluster_part.name
  end

  private

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
