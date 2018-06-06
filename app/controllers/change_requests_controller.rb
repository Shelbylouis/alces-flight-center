class ChangeRequestsController < ApplicationController

  before_action :assign_case

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

end
