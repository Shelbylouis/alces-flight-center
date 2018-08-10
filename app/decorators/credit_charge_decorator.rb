class CreditChargeDecorator < ApplicationDecorator
  delegate_all

  def credit_usage_card
    kase = object.case.decorate
    link_text = "#{kase.display_id} - #{kase.subject}"
    h.render 'clusters/credit_charge_entry',
             amount: -amount,
             date: effective_date,
             time_to_response: time_to_response_str(kase) do
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

  private

  def time_to_response_str(kase)
    if kase.user.admin?
      'Raised by admin'
    else
      first_admin_comment = kase.first_admin_comment

      if first_admin_comment.nil?
        h.raw('<i class="fa fa-hourglass-half"></i> N/A')
      else
        time_to_response = kase.created_at
                               .business_time_until(first_admin_comment.created_at)
                               .floor
        hours = time_to_response / 3600
        mins = (time_to_response / 60) % 60
        h.raw("<i class=\"fa fa-hourglass-half\"></i> #{hours}h #{mins}m")
      end
    end
  end
end
