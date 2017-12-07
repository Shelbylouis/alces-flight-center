class CasesController < ApplicationController
  before_action :require_login

  def index
    @cases = current_site.cases
    @title = if current_user.admin?
               'Manage support cases'
             else
               'Support case archive'
             end

    @cases.map(&:update_ticket_status!) if current_user.admin?
  end

  def new
    @title = "Create new support case"
    @case_categories = CaseCategory.all

    cluster_id = params[:cluster_id]
    component_id = params[:component_id]
    service_id = params[:service_id]
    @clusters = if cluster_id
                  [Cluster.find(cluster_id)]
                elsif component_id
                  @single_part = Component.find(component_id)
                  [@single_part.cluster]
                elsif service_id
                  @single_part = Service.find(service_id)
                  [@single_part.cluster]
                else
                  current_site.clusters
    end
  end

  def create
    @case = Case.new(case_params.merge(user: current_user))

    respond_to do |format|
      if @case.save
        flash[:success] = 'Support case successfully created.'

        format.json do
          # Return no errors and success status to case form app; it will
          # handle redirect appropriately.
          render json: { errors: '' }
        end
      else
        errors = format_errors(@case)

        format.json do
          # Return errors to case form app.
          render json: { errors: errors }, status: 422
        end
      end

      format.html do
        flash[:error] = "Error creating support case: #{errors}." if errors
        redirect_path = @case.cluster ? cluster_path(@case.cluster) : root_path
        redirect_to redirect_path
      end
    end
  end

  def archive
    archived_change_action(
      archived: true,
      success_flash: 'Support case archived.'
    )
  end

  def restore
    archived_change_action(
      archived: false,
      success_flash: 'Support case restored from archive.'
    )
  end

  def request_maintenance_window
    support_case = Case.find(params[:id])
    support_case.request_maintenance_window!(requestor: current_user)
    redirect_to site_cases_path(support_case.site)
  end

  def end_maintenance_window
    support_case = Case.find(params[:id])
    support_case.end_maintenance_window!
    redirect_to site_cases_path(support_case.site)
  end

  private

  def case_params
    params.require(:case).permit(
      :issue_id, :cluster_id, :component_id, :service_id, :details
    )
  end

  def archived_change_action(archived:, success_flash:)
    @case = Case.find(params[:id])
    @case.archived = archived
    if @case.save
      flash[:success] = success_flash
    else
      flash[:error] = "Error updating support case: #{format_errors(support_case)}"
    end
    redirect_to root_path
  end
end
