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

  def show
    @cr = @case.change_request.decorate
  end

  def propose
    change_action 'Change request %s has been submitted for customer authorisation.' do |cr|
      cr.propose!(current_user)
    end
  end

  def decline
    change_action 'Change request %s declined.' do |cr|
      cr.decline!(current_user)
    end
  end

  def authorise
    change_action 'Change request %s authorised.' do |cr|
      cr.authorise!(current_user)
    end
  end

  def handover
    change_action 'Change request %s handed over for customer approval.' do |cr|
      cr.handover!(current_user)
    end
  end

  def complete
    change_action 'Change request %s completed.' do |cr|
      cr.complete!(current_user)
    end
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def cr_params
    params.require(:change_request).permit(:details, :credit_charge)
  end

  def change_action(success_flash)
    cr = @case.change_request
    begin
      yield(cr)
      cr.save!
      flash[:success] = success_flash % cr.case.display_id
    rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
      flash[:error] = "Error updating change request: #{format_errors(cr)}"
    end
    redirect_to cluster_case_change_request_path(@case.cluster, @case, cr)
  end

end
