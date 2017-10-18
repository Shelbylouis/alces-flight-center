class CasesController < ApplicationController
  before_action :require_login

  def index
    @cases = current_site.cases
    @title = 'Support case archive'
  end

  def new
    @title = "Create new support case"
    @case = Case.new
    assign_form_variables
  end

  def create
    @case = Case.new(case_params.merge(user: current_user))

    if @case.save
      flash[:success] = 'Support case successfully created.'

      # Return no errors and success status to case form app; it will handle
      # redirect appropriately.
      render :json => {errors: ''}
    else
      # Return errors to case form app.
      render json: {errors: format_errors(@case)}, status: 422
    end
  end

  def archive
    @case = Case.find(params[:id])
    @case.archived = true
    if @case.save
      flash[:success] = 'Support case archived.'
    else
      flash_object_errors(@case)
    end
    redirect_to root_path
  end

  private

  def case_params
    params.require(:case).permit(
      :issue_id, :cluster_id, :component_id, :details
    )
  end

  def format_errors(support_case)
    # XXX Improve error handling - for now we just return a formatted string of
    # all errors; could be worth returning JSON which can be decoded and
    # displayed inline with fields in app.
    support_case.errors.messages.map do |field, messages|
      "#{field} #{messages.join(', ')}"
    end.join('; ')
  end

  def flash_object_errors(support_case)
    flash[:error] = "Error creating support case: #{format_errors(support_case)}"
  end

  def assign_form_variables
    @case_categories = CaseCategory.all
    @site_clusters = current_site.clusters
  end
end
