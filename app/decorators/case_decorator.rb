class CaseDecorator < ApplicationDecorator
  delegate_all

  def maintenance_window_form_info
    [
      "RT ticket #{rt_ticket_id}",
      created_at.to_formatted_s(:long),
      "#{case_category.name} - #{issue.name}",
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
end
