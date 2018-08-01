class ClustersController < ApplicationController
  decorates_assigned :cluster

  additional_read_only_actions = [:credit_usage, :documents, :checks]
  after_action :verify_authorized,
    except: NO_AUTH_ACTIONS + additional_read_only_actions

  def credit_usage
    credit_events = ClusterCreditEvents.new(@cluster, start_date, end_date)

    @events = credit_events.events.map(&:decorate)

    @accrued = credit_events.total_accrual
    @used = credit_events.total_charges

    @free_of_charge = credit_events.cases_closed_without_charge
  end

  def deposit

    authorize @cluster

    deposit_params = params.require(:credit_deposit)
                           .permit(:amount, :effective_date)
                           .merge(user: current_user)

    begin
      deposit = @cluster.credit_deposits.create!(deposit_params)
      flash[:success] = "#{view_context.pluralize(deposit.amount, 'credit')} added to cluster #{@cluster.name}."
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = "Error while trying to deposit credits for this cluster: #{e.message}"
    end

    redirect_to cluster_credit_usage_path(@cluster)
  end

  def enter_check_results
    authorize @cluster
  end

  def check_results
    authorize @cluster

    @cluster.cluster_checks.each do |cluster_check|
      id = cluster_check.id

      unless Component.find_by_id(params["#{id}-component"]).nil?
        @new_log = @cluster.logs.build(
          details: params["#{id}-comment"],
          component_id: params["#{id}-component"],
          user: current_user
        )
      end

      result = CheckResult.new(
        cluster_check: cluster_check,
        date: Date.current,
        user: current_user,
        result: params["#{id}-result"],
        comment: params["#{id}-comment"],
        log_id: @new_log ? @new_log.id : nil
      )

      if result.save
        if @new_log
          SlackNotifier.log_notification(@new_log) if @new_log.save
        end

        flash[:success] = 'Cluster check results successfully saved.'
      else
        flash[:error] = 'Error while trying to save the cluster check results.'
      end
    end

    redirect_to cluster_checks_path(@cluster)
  end

  def checks
    @date = params[:date]&.to_date || Date.current
    @date_checks = check_results_by_date(@date)
  end

  def preview
      @check_result_comment ||= nil
      params.each do |key, value|
        @check_result_comment = value if key.include? 'comment'
      end

      authorize @cluster, :create?

      render layout: false
  end

  def write
      params.each do |key, value|
        @check_result_comment = value if key.include? 'comment'
      end

      authorize @cluster, :create?

      render layout: false
  end

  private

  def start_date
    @start_date ||= begin
      parse_start_date.beginning_of_quarter
    rescue
      Date.today.beginning_of_quarter
    end
  end

  def end_date
    @end_date ||= start_date.end_of_quarter
  end

  def parse_start_date
    Date.parse(params[:start_date])
  end

  def check_results_by_date(date)
    @cluster.check_results.where(date: date).order(:cluster_check_id)
  end
end
