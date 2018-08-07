class CreditChargeDecorator < ApplicationDecorator
  delegate_all

  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"
    time_to_response_str = "Raised by admin"
    first_admin_comment = nil
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
        time_to_response_str = "N/A"
      else
          time_to_response = kase.created_at.business_time_until(first_admin_comment.created_at).floor
          hours = time_to_response/3600
          mins = (time_to_response/60)%60
          time_to_response_str = h.raw("<i class=\"fa fa-hourglass-half\"></i> #{hours}h #{mins}m")
      end
    end
    h.render 'clusters/credit_charge_entry',
             amount: -amount,
             date: effective_date,
             time_to_response: time_to_response_str do
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
