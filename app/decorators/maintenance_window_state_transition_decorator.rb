class MaintenanceWindowStateTransitionDecorator < ApplicationDecorator

  def event_card
    h.render 'cases/event',
             date: object.created_at,
             name: object.user&.name || 'Flight Center',
             text: comment_text,
             type: 'wrench',
             details: 'Maintenance Information'
  end

  def comment_text
    comment_template = "maintenance_windows/transitions/#{object.event}"
    h.render(comment_template, transition: self).squish
  end

  def associated_model_links
    window.associated_model_links
  end

  def associated_model_names
    window.associated_model_names
  end

  def window
    object.maintenance_window.decorate
  end

  def cluster_dashboard_url
    h.cluster_maintenance_windows_url(window.associated_cluster)
  end

  def requested_start
    window.requested_start.to_formatted_s(:short)
  end

  def expected_end
    window.expected_end.to_formatted_s(:short)
  end

end
