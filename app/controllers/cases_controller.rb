class CasesController < ApplicationController
  before_action :require_login

  def index
    @site = current_site
    @title = "Support for site #{@site.name}"
  end

  def new
    @title = "Create new support case"
    @case = Case.new
    assign_form_variables
  end

  def create
    @case = Case.new(case_params.merge(contact: current_user))

    if @case.save
      flash[:success] = 'Support case successfully created.'
      redirect_to :cases
    else
      # XXX Improve error handling
      errors = @case.errors.messages.map do |field, messages|
        "#{field} #{messages.join(', ')}"
      end.join('; ')
      flash[:error] = "Error creating support case: #{errors}"

      assign_form_variables
      render :new
    end
  end

  private

  def case_params
    params.require(:case).permit(
      :case_category_id, :cluster_id, :component_id, :details
    )
  end

  def assign_form_variables
    @case_categories = CaseCategory.all
    @site_clusters = current_site.clusters
    @site_components = current_site.components
  end
end
