class MaintenanceWindowStateTransitionDecorator < ApplicationDecorator

  def event_card
    h.render 'maintenance_windows/transition', transition: object
  end

  def comment_text
    comment_template = "maintenance_windows/transitions/#{object.event}"
    h.render comment_template, transition: self
  end

  def associated_model
    window.associated_model
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
