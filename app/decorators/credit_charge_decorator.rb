class CreditChargeDecorator < ApplicationDecorator
  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"

    h.render 'clusters/credit_charge_entry',
             amount: -object.amount,
             date: object.created_at do
      h.link_to link_text, h.case_path(kase), class: 'text-danger'
    end
  end
end
