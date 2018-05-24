class ClustersController < ApplicationController
  decorates_assigned :cluster

  def credit_usage

    @events = (charges + deposits).sort_by(&:created_at)

    @accrued = deposits.reduce(0) do |total, deposit|
      total += deposit.amount
    end

    @used = charges.reduce(0) do |total, kase|
      total += kase.credit_charge.amount
    end

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
    @cluster.cases.with_charge_in_period(start_date, end_date)
  end

  def deposits
    @cluster.credit_deposits.in_period(start_date, end_date)
  end
end
