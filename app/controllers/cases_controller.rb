class CasesController < ApplicationController
  before_action :require_login

  decorates_assigned :site

  def index(archive: false)
    @site = current_site
    @archive = archive
    current_site.cases.map(&:update_ticket_status!) if current_user.admin?
  end

  def archives
    index(archive: true)
    render :index
  end

  def show
    @case = Case.find(params[:id]).decorate
    @comment = @case.case_comments.new
  end

  def new
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
    @case = Case.new(case_params.merge(user: current_user)).decorate

    respond_to do |format|
      if @case.save
        flash[:success] = "Support case #{@case.display_id} successfully created."

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
    change_action "Support case %s archived." do |kase|
      kase.archive!(current_user)
    end
  end

  def resolve
    change_action "Support case %s resolved." do |kase|
      kase.resolve!(current_user)
    end
  end

  private

  def case_params
    params.require(:case).permit(
      :issue_id,
      :cluster_id,
      :component_id,
      :service_id,
      :subject,
      :tier_level,
      fields: [:type, :name, :value, :optional],
    )
  end

  def change_action(success_flash, &block)
    @case = Case.find(params[:id]).decorate
    begin
      block.call(@case)
      @case.save!
      flash[:success] = success_flash % @case.display_id
    rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
      flash[:error] = "Error updating support case: #{format_errors(@case)}"
    end
    redirect_to @case
  end
end
