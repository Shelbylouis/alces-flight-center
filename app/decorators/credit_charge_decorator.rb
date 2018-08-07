class CreditChargeDecorator < ApplicationDecorator
  delegate_all

  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"
    time_to_response = 0
    first_admin_comment = nil
    #if an admin created the case, time to response is 0
    if !kase.user.admin?
      kase.events.reverse.each do |event|
        if event.instance_of?(CaseComment)
          if event.user.admin?
            first_admin_comment = event
            break
          end
        end
      end
      if first_admin_comment.nil?
        time_to_response = "N/A" 
      else
        time_to_response = kase.created_at.business_time_until(first_admin_comment.created_at)
      end
    end
    h.render 'clusters/credit_charge_entry',
             amount: -amount,
             date: effective_date,
             time_to_response: time_to_response do
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
