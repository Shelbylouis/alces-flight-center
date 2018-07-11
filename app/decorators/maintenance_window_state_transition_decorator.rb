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
    window.associated_models.map { |m| m.decorate.links }.join(', ')
  end

  def associated_model_names
    window.associated_models.map { |m| "#{m.name} (#{m.readable_model_name})"}.join(', ')
  end

  def window
    object.maintenance_window
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
