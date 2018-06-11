class ClustersController < ApplicationController
  decorates_assigned :cluster

  # :credit_usage is a read-only action so should not require authorization.
  after_action :verify_authorized, except: NO_AUTH_ACTIONS + [:credit_usage]

  def credit_usage

    @events = @cluster.credit_events_in_period(start_date, end_date)
                      .map(&:decorate)

    @accrued = @cluster.total_accrual_in_period(start_date, end_date)
    @used = @cluster.total_charges_in_period(start_date, end_date)

    @free_of_charge = @cluster.cases_closed_free_in_period(start_date, end_date)

  end

  def deposit

    authorize @cluster

    deposit_params = params.require(:credit_deposit)
                           .permit(:amount)
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
