class CasesController < ApplicationController
  before_action :require_login

  def index
    @open_cases = current_site.cases.where(status: :open)
    @title = "Support for site #{current_site.name}"
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
      redirect_to :cases
    else
      flash_object_errors(@case)
      assign_form_variables
      render :new
    end
  end

  def close
    @case = Case.find(params[:id])
    @case.status = :closed
    if @case.save
      flash[:success] = 'Support case closed.'
    else
      flash_object_errors(@case)
    end
    redirect_to cases_path
  end

  private

  def case_params
    params.require(:case).permit(
      :case_category_id, :cluster_id, :component_id, :details
    )
  end

  def flash_object_errors(support_case)
    # XXX Improve error handling
    errors = support_case.errors.messages.map do |field, messages|
      "#{field} #{messages.join(', ')}"
    end.join('; ')
    flash[:error] = "Error creating support case: #{errors}"
  end

  def assign_form_variables
    @case_categories = CaseCategory.all
    @site_clusters = current_site.clusters
    @site_components = current_site.components
  end
end
