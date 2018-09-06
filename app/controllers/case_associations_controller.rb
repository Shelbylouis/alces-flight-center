class CaseAssociationsController < ApplicationController

  before_action :assign_case

  ASSOCIATION_PARAM_REGEX = /^(?<type>.*)-(?<id>[0-9]+)$/

  def edit
    authorize(@case, :edit_associations?)
    @title = "Edit affected components: #{@case.display_id}"
  end

  def update
    authorize(@case, :edit_associations?)

    begin
      assocs = map_association_params

      new_assocs = if assocs.include?(@case.cluster)
                     [@case.cluster]
                   else
                     filter_group_children(assocs)
                   end

      validate_as_if_set(new_assocs)

      @case.associations = new_assocs

      flash[:success] = "Updated affected components for support case #{@case.display_id}."
      CaseMailer.change_association(@case, current_user).deliver_later

    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = "Unable to update associations, an error occurred: #{format_errors(e.record)}"
    end

    redirect_to case_path(@case)
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def map_association_params
    assoc_param.map do |assoc|
      assoc_data = ASSOCIATION_PARAM_REGEX.match(assoc)
      if assoc_data
        Kernel.const_get(assoc_data[:type]).find(assoc_data[:id])
      end
    end.compact
  end

  def filter_group_children(assocs)
    assocs.select do |assoc|
      !assoc.respond_to?(:component_group) ||
        !assocs.include?(assoc.component_group)
    end
  end

  def validate_as_if_set(new_assocs)
    @case.without_auditing do
      CaseAssociation.without_auditing do
        old_assocs = @case.associations
        @case.associations = new_assocs
        @case.validate!
      ensure
        @case.associations = old_assocs
      end
    end
  end

  def assoc_param
    params[:associations] || []
  end

end
