class ClustersController < ApplicationController
  decorates_assigned :cluster

  additional_read_only_actions = [:credit_usage, :documents]
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
    rescue
      flash[:error] = 'Error while trying to deposit credits for this cluster.'
    end

    redirect_to cluster_credit_usage_path(@cluster)
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
end
