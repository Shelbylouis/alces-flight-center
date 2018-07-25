# Represents a set of credit events for a cluster in a given period.
class ClusterCreditEvents

  def initialize(cluster, start_date, end_date)
    @cluster = cluster
    @start_date = Time.zone.local_to_utc(start_date.to_datetime)
    @end_date = Time.zone.local_to_utc(end_date.to_datetime)
  end

  def events
    (charges + deposits)
      .sort_by(&:effective_date)
      .reverse!
  end

  def charges
    @charges ||= @cluster.credit_charges.in_period(
      @start_date,
      @end_date
    )
  end

  def deposits
    @deposits ||= @cluster.credit_deposits.in_period(
      @start_date,
      @end_date
    )
  end

  def total_accrual
    add_up deposits
  end

  def total_charges
    add_up charges
  end

  def cases_closed_without_charge
    charges.where(amount: 0).count
  end

  private

  def add_up(things)
    things.reduce(0) do |total, thing|
      total += thing.amount
    end
  end

end
