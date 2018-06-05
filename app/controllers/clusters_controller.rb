class ClustersController < ApplicationController
  decorates_assigned :cluster

  def credit_usage

    @events = (charges + deposits)
              .sort_by(&:created_at)
              .reverse!
              .map(&:decorate)

    @accrued = add_up(deposits)

    @used = add_up(charges)

    @free_of_charge = charges.where(amount: 0).count

  end

  def deposit

    amount = params.require(:credit_deposit).permit(:amount).require(:amount).to_i

    begin
      @cluster.credit_deposits.create!(amount: amount, user: current_user)
      flash[:success] = "#{view_context.pluralize(amount, 'credit')} added to cluster #{@cluster.name}."
    rescue
      flash[:error] = 'Error while trying to deposit credits for this cluster.'
    end

    redirect_to cluster_credit_usage_path(@cluster)
  end

  private

  def add_up(things)
    things.reduce(0) do |total, thing|
      total += thing.amount
    end
  end

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
    @charges ||= @cluster.credit_charges.in_period(
      Time.zone.local_to_utc(start_date.to_datetime),
      Time.zone.local_to_utc(end_date.to_datetime)
    )
  end

  def deposits
    @deposits ||= @cluster.credit_deposits.in_period(
      Time.zone.local_to_utc(start_date.to_datetime),
      Time.zone.local_to_utc(end_date.to_datetime)
    )
  end

end
