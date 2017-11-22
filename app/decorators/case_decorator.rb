class CaseDecorator < ApplicationDecorator
  delegate_all

  def association_info
    cluster_link = h.link_to cluster.name, h.cluster_path(cluster)

    info = if component
             "#{link_to_associated_component} (#{cluster_link})"
           elsif service
             service_link = h.link_to service.name, h.service_path(service)
             "#{service_link} (#{cluster_link})"
           else
             cluster_link
           end

    h.raw(info)
  end

  def rt_ticket_url
    "http://helpdesk.alces-software.com/rt/Ticket/Display.html?id=#{rt_ticket_id}"
  end

  private

  def link_to_associated_component
    link_text = component.name
    title = nil

    if under_maintenance?
      link_text += '&nbsp;' + h.icon('wrench', inline: true)
      title = 'Component currently under maintenance for this Case'
    end

    h.link_to h.raw(link_text), h.component_path(component), title: title
  end
end
