class CasesController < ApplicationController
  decorates_assigned :site

  after_action :verify_authorized, except: NO_AUTH_ACTIONS + [
    :redirect_to_canonical_path,
  ]

  def index
    @filters = filters_spec
    @cases = filtered_cases(@filters[:active])
    render :index
  end

  def show
    @case = case_from_params
    if [AllSites, Site].include? @scope.class
      redirect_to cluster_case_path(@case.cluster, @case)
    else
      not_found unless @scope.cases.include? @case
      @comment = @case.case_comments.new
      @title = "#{@case.display_id}: #{@case.subject}"
    end
  end

  def new
    authorize Case
    cluster_id = params[:cluster_id]
    component_id = params[:component_id]
    service_id = params[:service_id]
    @clusters = if cluster_id
                  [Cluster.find_from_id!(cluster_id)]
                elsif component_id
                  @single_part = Component.find(component_id)
                  [@single_part.cluster]
                elsif service_id
                  @single_part = Service.find(service_id)
                  [@single_part.cluster]
                else
                  current_site.clusters
                end
    @pre_selected = get_pre_selections
  end

  def create
    my_params = case_params

    service_id = my_params.delete(:service_id)
    component_id = my_params.delete(:component_id)

    @case = Case.new(my_params.merge(user: current_user))
    authorize @case

    if service_id.present?
      @case.services << Service.find(service_id)
    end

    if component_id.present?
      @case.components << Component.find(component_id)
    end

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
        redirect_back fallback_location: @case.cluster ? cluster_path(@case.cluster) : root_path
      end
    end
  end

  def close
    charge_params = params.require(:credit_charge)
                          .permit(:amount)
                          .merge(user: current_user)

    change_action "Support case %s closed." do |kase|
      kase.create_credit_charge(charge_params)
      kase.close!(current_user)
    end
  rescue ActionController::ParameterMissing
    flash[:error] = 'You must specify a credit charge to close this case.'
    redirect_to @scope.dashboard_case_path(case_from_params)
  end

  def assign
    new_assignee_id = params[:case][:assignee_id]
    new_assignee = new_assignee_id.empty? ? nil : User.find(new_assignee_id)
    success_flash = new_assignee ?
                        "Support case %s assigned to #{new_assignee.name}."
                        : 'Support case %s unassigned.'

    change_action success_flash do |kase|
      kase.assignee = new_assignee
    end
  end

  def resolve
    change_action "Support case %s resolved." do |kase|
      kase.resolve!(current_user)
    end
  end

  def set_time
    times = params.require(:time).permit(:hours, :minutes)
    total_time = (times.require(:hours).to_i * 60) + times.require(:minutes).to_i

    change_action "Updated 'time worked' for support case %s." do |kase|
      kase.time_worked = total_time
    end
  end

  def escalate
    change_action "Support case %s escalated." do |kase|
      kase.tier_level = 3
    end
  end

  def set_commenting
    enabled = params.require(:comments_enabled)
    verb = enabled == 'true' ? 'enabled' : 'disabled'

    change_action "Commenting #{verb} for contacts on case %s" do |kase|
      kase.comments_enabled = enabled
    end
  end

  def redirect_to_canonical_path
    kase = case_from_params
    redirect_to case_path(kase)
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
      fields: [:type, :name, :value, :optional, :help],
      tool_fields: {}
    )
  end

  def change_action(success_flash, &block)
    @case = case_from_params
    begin
      block.call(@case)
      @case.save!
      flash[:success] = success_flash % @case.display_id
    rescue ActiveRecord::RecordInvalid, StateMachines::InvalidTransition
      flash[:error] = "Error updating support case: #{format_errors(@case)}"
    end
    redirect_to @scope.dashboard_case_path(@case)
  end

  def case_from_params
    Case.find_from_id!(params.require(:id))
      .tap { |c| authorize c }
      .decorate
  end

  def get_pre_selections
    if params[:tool].present?
      {
        tool: params[:tool],
      }
    else
      {}
    end
  end

  def filtered_cases(filters)
    @scope.cases.filter(
      filters
    )
  end

  def case_filters
    params.permit(
      :state,
      state: []  # Allow state to be a singleton or array
    ).to_h
  end


  def filters_spec
    {
      active: case_filters,
      values: {},
    }
  end
end
