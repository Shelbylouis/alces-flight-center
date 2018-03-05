
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
      Maintenance requested for #{associated_model.name} from
      #{requested_start} until #{requested_end} by #{window.requested_by.name};
      to proceed this maintenance must be confirmed on the cluster dashboard:
      #{cluster_dashboard_url}.
    EOF
  end

  def requested_start
    window.requested_start.to_formatted_s(:short)
  end

  def requested_end
    window.requested_end.to_formatted_s(:short)
  end

  def confirmed_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} confirmed by
      #{window.confirmed_by.name}; this maintenance has been scheduled.
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
      Request for maintenance of #{associated_model.name} rejected by
      #{window.rejected_by.name}.
    EOF
  end

  def expired_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} was not confirmed
      before requested start date; this maintenance has been automatically
      cancelled.
    EOF
  end

  def started_comment
    <<~EOF
      Scheduled maintenance of #{associated_model.name} has automatically
      started.
    EOF
  end

  def ended_comment
    <<~EOF
      Scheduled maintenance of #{associated_model.name} has automatically
      ended.
    EOF
  end

  def add_rt_ticket_correspondence(text)
    window.case.add_rt_ticket_correspondence(text)
  end

  def cluster_dashboard_url
    Rails.application.routes.url_helpers.cluster_url(window.associated_cluster)
  end
end
