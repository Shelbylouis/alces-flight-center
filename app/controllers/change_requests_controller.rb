class ChangeRequestsController < ApplicationController

  before_action :assign_case

  def new
    @cr = ChangeRequest.new
  end

  def create
    @case.create_change_request!(cr_params)
    redirect_to case_path(@case.display_id)
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def cr_params
    params.require(:change_request).permit(:details, :credit_charge)
  end

end
