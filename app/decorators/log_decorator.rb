class LogDecorator < ApplicationDecorator
  delegate_all
  def event_card
    h.render 'cases/event',
             name: object.engineer.name,
             date: object.created_at,
             text: object.rendered_details,
             formatted: true,
             type: 'pencil-square-o',
             details: 'Log Entry'
  end

  def preview_path
    if component
      h.preview_component_logs_path(component)
    else
      h.preview_cluster_logs_path(cluster)
    end
  end

  def write_path
    if component
      h.write_component_logs_path(component)
    else
      h.write_cluster_logs_path(cluster)
    end
  end
end
