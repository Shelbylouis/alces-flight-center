class CasesController < ApplicationController
  before_action :require_login

  def index
    @cases = current_site.cases
    @title = 'Support case archive'
  end

  def new
    @title = "Create new support case"
    @case = Case.new
    @case_categories = CaseCategory.all

    cluster_id = params[:cluster_id]
    component_id = params[:component_id]
    service_id = params[:service_id]
    @clusters = if cluster_id
                  [current_site_cluster(id: cluster_id)]
                elsif component_id
                  @single_part = current_site_component(id: component_id)
                  [@single_part.cluster]
                elsif service_id
                  @single_part = current_site_service(id: service_id)
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

  private

  def current_site_cluster(id:)
    Cluster.find_by(id: id, site: current_site) || not_found
  end

  def current_site_component(id:)
    current_site.components.find_by(id: id) || not_found
  end

  def current_site_service(id:)
    current_site.services.find_by(id: id) || not_found
  end

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
      flash_object_errors(@case)
    end
    redirect_to root_path
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
end