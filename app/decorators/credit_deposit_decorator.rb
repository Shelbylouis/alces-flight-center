class CreditDepositDecorator < ApplicationDecorator

  def credit_usage_card
    h.render 'clusters/credit_charge_entry',
             amount: object.amount,
             date: object.created_at do
      'Credits added'
    end
  end

end