class CaseDecorator < ApplicationDecorator
  delegate_all

  # Note: These should match values used in `Tier.Level.description` in Case
  # form app.
  TIER_DESCRIPTIONS = {
    1 => 'Tool',
    2 => 'Support',
    3 => 'Consultancy',
  }.freeze

  def user_facing_state
    model.state.to_s.titlecase
  end

  def display_id
    "##{object.id}"
  end

  def case_select_details
    [
      "RT ticket #{rt_ticket_id}",
      created_at.to_formatted_s(:long),
      subject,
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

  def ticket_link
    h.link_to(rt_ticket_id, h.case_path(self))
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

  def tier_description
    unless TIER_DESCRIPTIONS.has_key?(tier_level)
      raise "Unhandled tier_level: #{tier_level}"
    end
    description = TIER_DESCRIPTIONS[tier_level]
    "#{tier_level} (#{description})"
  end

  def commenting_disabled?
    current_user.contact? && !consultancy?
  end
end
