
MaintenanceNotifier = Struct.new(:window) do
  def add_transition_comment(state)
    comment_method = "#{state}_comment".to_sym
    comment = send(comment_method).squish
    add_rt_ticket_correspondence(comment)
  end

  private

  delegate :associated_model, to: :window

  def requested_comment
    <<-EOF
      Maintenance requested for #{associated_model.name} by
      #{window.requested_by.name}; to proceed this maintenance must be
      confirmed on the cluster dashboard: #{cluster_dashboard_url}.
    EOF
  end

  def confirmed_comment
    <<~EOF
      Maintenance of #{associated_model.name} confirmed by
      #{window.confirmed_by.name}; this #{associated_model.readable_model_name}
      is now under maintenance.
    EOF
  end

  def cancelled_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} cancelled by
      #{window.cancelled_by.name}.
    EOF
  end

  def rejected_comment
    <<~EOF
      Maintenance of #{associated_model.name} rejected by
      #{window.rejected_by.name}
    EOF
  end

  def expired_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} was not confirmed
      before requested start; this maintenance has been automatically
      cancelled.
    EOF
  end

  def started_comment
    "confirmed maintenance of #{associated_model.name} started."
  end

  def ended_comment
    "#{associated_model.name} is no longer under maintenance."
  end

  def add_rt_ticket_correspondence(text)
    window.case.add_rt_ticket_correspondence(text)
  end

  def cluster_dashboard_url
    Rails.application.routes.url_helpers.cluster_url(window.associated_cluster)
  end
end
