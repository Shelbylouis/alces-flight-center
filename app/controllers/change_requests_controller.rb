class ChangeRequestsController < ApplicationController

  before_action :assign_case

  def new
    @cr = ChangeRequest.new
  end

  def create
    cr = @case.build_change_request(cr_params)

    if cr.save
      flash[:success] = "Created change request for case #{@case.display_id}."
      redirect_to case_path(@case.display_id)
    else
      errors = format_errors(cr)
      flash[:error] = "Error creating change request: #{errors}." if errors
      # Show the form again, with the data previously entered.
      @cr = cr
      render 'change_requests/new'
    end

  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def cr_params
    params.require(:change_request).permit(:details, :credit_charge)
  end

end
