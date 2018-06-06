class ChangeRequestsController < ApplicationController

  before_action :assign_case

  def new
    @cr = ChangeRequest.new
  end

  def create
    p params
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

end
