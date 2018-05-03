class CasesController < ApplicationController
  before_action :require_login

  decorates_assigned :site

  def index(show_resolved: false)
    @site = current_site
    @show_resolved = show_resolved
  end

  def resolved
    index(show_resolved: true)
    render :index
  end

  def show
    @case = case_from_params
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
    @case = Case.new(case_params.merge(user: current_user))

    respond_to do |format|
      if @case.save
        flash[:success] = "Support case #{@case.display_id} successfully created."

        format.json do
          # Return no errors and success status to case form app; it will
          # redirect to the path we give it.
          render json: { redirect: case_path(@case) }
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

  def close
    change_action "Support case %s closed." do |kase|
      kase.close!(current_user)
    end
  end

  def assign
    new_assignee_id = params[:case][:assignee_id]
    new_assignee = new_assignee_id.empty? ? nil : User.find(new_assignee_id)
    success_flash = new_assignee ?
                        "Support case %s assigned to #{new_assignee.name}."
                        : 'Support case %s unassigned.'

    change_action success_flash, redirect_path: case_path do |kase|
      kase.assignee = new_assignee
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

  def change_action(success_flash, redirect_path: case_path, &block)
    @case = case_from_params
    begin
      block.call(@case)
      @case.save!
      flash[:success] = success_flash % @case.display_id
    rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
      flash[:error] = "Error updating support case: #{format_errors(@case)}"
    end
    redirect_to redirect_path
  end

  def case_from_params
    Case.find_from_id!(params.require(:id)).decorate
  end
end
