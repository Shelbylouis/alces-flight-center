class CaseDecorator < ApplicationDecorator
  delegate_all

  def case_select_details
    [
      "RT ticket #{rt_ticket_id}",
      created_at.to_formatted_s(:long),
      issue_details,
      associated_model.name,
      "Created by #{user.name}"
    ].join(' | ')
  end

  def association_info
    associated_model.decorate.links
  end

  def rt_ticket_url
    "http://helpdesk.alces-software.com/rt/Ticket/Display.html?id=#{rt_ticket_id}"
  end

  def chargeable_symbol
    h.boolean_symbol(chargeable)
  end

  def credit_charge_info
    if credit_charge
      credit_charge.amount.to_s
    elsif chargeable
      'Pending'
    else
      'N/A'
    end
  end

  private

  def issue_details
    category_prefix = category ? "#{category.name} - " : ''
    category_prefix + issue.name
  end
end
