class ChangeRequestsController < ApplicationController

  before_action :assign_case
  decorates_assigned :cr

  def new
    authorize ChangeRequest
    @cr = ChangeRequest.new
  end

  def create
    authorize @case
    @case.tier_level = 4

    cr = @case.build_change_request(cr_params)
    authorize cr

    if @case.save
      text = "Created change request for case #{@case.display_id}."
      flash[:success] = text
      email(
        [
          @case,
          text,
          current_user,
          {}
        ]
      )
      redirect_to case_path(@case)
    else
      errors = format_errors(cr)
      flash[:error] = "Error creating change request: #{errors}." if errors
      # Show the form again, with the data previously entered.
      @cr = cr
      render :new
    end

  end

  def show
    assign_cr
  end

  def edit
    assign_cr
    authorize @cr
  end

  def update
    change_action 'Change request %s updated.' do |cr|
      cr.assign_attributes(cr_params)
    end
  end

  def propose
    change_action_and_email 'Change request %s has been submitted for customer authorisation.' do |cr|
      cr.propose!(current_user)
    end
  end

  def decline
    change_action_and_email 'Change request %s declined.' do |cr|
      cr.decline!(current_user)
    end
  end

  def authorise
    change_action_and_email 'Change request %s authorised.' do |cr|
      cr.authorise!(current_user)
    end
  end

  def handover
    change_action_and_email 'Change request %s handed over for customer approval.' do |cr|
      cr.handover!(current_user)
    end
  end

  def complete
    change_action_and_email 'Change request %s completed.' do |cr|
      cr.complete!(current_user)
    end
  end

  def cancel
    change_action_and_email 'Change request %s cancelled.' do |cr|
      @recipients = {}
      cr.cancel!(current_user)
    end
  end

  def request_changes
    change_action_and_email 'Further changes requested on change request %s.' do |cr|
      cr.request_changes!(current_user)
    end
  end

  def preview
    @cr = @case.change_request || @case.build_change_request
    @cr.update(cr_params)

    authorize @cr, :create?

    render layout: false
  end

  def write
    @cr = @case.change_request || @case.build_change_request
    @cr.update(cr_params)

    authorize @cr, :create?

    render layout: false
  end

  private

  def assign_case
    @case = Case.find_from_id!(params.require(:case_id)).decorate
  end

  def assign_cr
    @cr = @case.change_request || not_found
  end

  def cr_params
    params.require(:change_request).permit(:description, :credit_charge)
  end

  def change_action(success_flash)
    cr = @case.change_request
    begin
      authorize cr
      yield(cr)
      cr.save!
      flash[:success] = success_flash % cr.case.display_id
    rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
      flash[:error] = "Error updating change request: #{format_errors(cr)}"
    end
    redirect_to cluster_case_change_request_path(@case.cluster, @case)
  end

  def change_action_and_email(success_flash)
    change_action success_flash do |cr|
      yield cr
      # A note on the order in which things are done:
      # Although the call to cr.save! doesn't happen until after this block
      # returns, the #event! methods on ChangeRequest will already have saved
      # the record to the database (or raised an exception). Hence we can be
      # certain that, if we reach this point, the model is saved and valid, so
      # it's safe to send the email.
      email(
        [
          cr.case,
          "The change request for this case #{cr.transitions.last.decorate.text_for_event}",
          current_user,
          @recipients ||= @case.email_recipients
        ]
      )
    end
  end

  def email(args)
    CaseMailer.change_request(*args).deliver_later
  end
end
