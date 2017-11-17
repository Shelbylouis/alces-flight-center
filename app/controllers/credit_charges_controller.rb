class CreditChargesController < ApplicationController
  def create
    charge = CreditCharge.new(credit_charge_params)

    if charge.save
      flash[:success] = 'Credit charge successfully added.'
    else
      flash[:danger] = "Error adding credit charge: #{format_errors(charge)}"
    end

    redirect_to site_cases_path(charge.site)
  end

  def update
    charge = CreditCharge.find(params[:id])

    if charge.update_attributes(credit_charge_params)
      flash[:success] = 'Credit charge successfully updated.'
    else
      flash[:danger] = "Error updating credit charge: #{format_errors(charge)}"
    end

    redirect_to site_cases_path(charge.site)
  end

  private

  def credit_charge_params
    params.require(:credit_charge).permit(
      :case_id, :amount
    ).merge(user: current_user)
  end
end
