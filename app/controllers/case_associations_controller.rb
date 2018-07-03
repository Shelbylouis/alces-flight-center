class CaseAssociationsController < ApplicationController

  before_action :assign_case

  ASSOCIATION_PARAM_REGEX = /^(?<type>.*)-(?<id>[0-9]+)$/

  def edit
    authorize(@case, :edit_associations?)
  end

  def update
    authorize(@case, :edit_associations?)

    @case.associations = map_association_params

    redirect_to case_path(@case)
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def map_association_params
    params[:associations].map do |assoc|
      assoc_data = ASSOCIATION_PARAM_REGEX.match(assoc)
      if assoc_data
        Kernel.const_get(assoc_data[:type]).find(assoc_data[:id])
      end
    end.compact
  end

end
