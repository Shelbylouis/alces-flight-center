class CreditChargeDecorator < ApplicationDecorator
  delegate_all

  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"

    h.render 'clusters/credit_charge_entry',
             amount: -object.amount,
             date: object.created_at do
      h.link_to link_text, h.case_path(kase), class: h.credit_value_class(-object.amount)
    end
  end

  def event_card
    h.render 'cases/event',
             admin_only: false,
             date: created_at,
             name: user.name,
             text:  "A charge of #{h.pluralize(amount, 'credit')} was added for this case.",
             type: 'usd'
  end
end
