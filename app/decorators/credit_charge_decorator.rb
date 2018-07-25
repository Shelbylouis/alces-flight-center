class CreditChargeDecorator < ApplicationDecorator
  delegate_all

  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"

    h.render 'clusters/credit_charge_entry',
             amount: -amount,
             date: effective_date do
      h.link_to link_text, h.case_path(kase), class: h.credit_value_class(-amount)
    end
  end

  def event_card
    h.render 'cases/event',
             admin_only: false,
             date: effective_date,
             name: user.name,
             text:  "A charge of #{h.pluralize(amount, 'credit')} was added for this case.",
             type: 'usd',
             details: 'Credit Charge'
  end
end
