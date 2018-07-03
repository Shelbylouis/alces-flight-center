class CaseAssociationsController < ApplicationController

  before_action :assign_case

  def edit
    authorize(@case, :edit_associations?)
  end

  def update
    authorize(@case, :edit_associations?)

    # TODO stuff goes here

    redirect_to case_path(@case)
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

end
