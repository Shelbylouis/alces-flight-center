class CaseDecorator < ApplicationDecorator
  delegate_all

  def association_info
    if component
      h.link_to component.name, h.component_path(component)
    elsif service
      h.link_to service.name, h.service_path(service)
    else
      h.raw('<em>N/A</em>')
    end
  end

  def rt_ticket_url
    "http://helpdesk.alces-software.com/rt/Ticket/Display.html?id=#{rt_ticket_id}"
  end
end
