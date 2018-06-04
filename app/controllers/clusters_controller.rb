class ClustersController < ApplicationController
  decorates_assigned :cluster

  def credit_usage

    @events = (charges + deposits)
              .sort_by(&:created_at)
              .reverse!
              .map(&:decorate)

    @accrued = deposits.reduce(0) do |total, deposit|
      total += deposit.amount
    end

    @used = charges.reduce(0) do |total, kase|
      total += kase.amount
    end

    @all_quarter_start_dates = all_quarter_start_dates

    @free_of_charge = charges.where(amount: 0).count

  end

  def deposit
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

  def charges
    @cluster.credit_charges.in_period(
      Time.zone.local_to_utc(start_date.to_datetime),
      Time.zone.local_to_utc(end_date.to_datetime)
    )
  end

  def deposits
    @cluster.credit_deposits.in_period(
      Time.zone.local_to_utc(start_date.to_datetime),
      Time.zone.local_to_utc(end_date.to_datetime)
    )
  end

  def all_quarter_start_dates
    first_quarter = @cluster.created_at.beginning_of_quarter
    last_quarter =  Date.today.beginning_of_quarter.to_datetime

    [].tap do |qs|
      curr_quarter = last_quarter
      while curr_quarter >= first_quarter
        qs << curr_quarter
        curr_quarter -= 3.months
      end
    end
  end
end
