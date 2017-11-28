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
    cluster_link = h.link_to cluster.name, h.cluster_path(cluster)

    info = if component
             "#{association_link(component)} (#{cluster_link})"
           elsif service
             "#{association_link(service)} (#{cluster_link})"
           else
             association_link(cluster)
           end

    h.raw(info)
  end

  def rt_ticket_url
    "http://helpdesk.alces-software.com/rt/Ticket/Display.html?id=#{rt_ticket_id}"
  end

  private

  # Link to main association for Case; indicates if association is under
  # maintenance due to this Case.
  def association_link(model)
    link_text = model.name
    title = nil

    model_name = model.readable_model_name

    if under_maintenance?
      link_text += '&nbsp;' + h.icon('wrench', inline: true)
      title = "#{model_name.capitalize} currently under maintenance for this Case"
    end

    path_helper = "#{model_name}_path"
    path = h.send(path_helper, model)

    h.link_to h.raw(link_text), path, title: title
  end
end
