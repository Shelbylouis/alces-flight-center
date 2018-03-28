
MaintenanceNotifier = Struct.new(:window) do
  def add_transition_comment(event)
    comment_method = "#{event}_comment".to_sym
    comment = send(comment_method).squish
    add_rt_ticket_correspondence(comment)
  end

  private

  delegate :associated_model, to: :window
  delegate :cluster_maintenance_windows_url,
    to: 'Rails.application.routes.url_helpers'

  def request_comment
    <<-EOF
      Maintenance requested for #{associated_model.name} from
      #{requested_start} until #{expected_end} by #{window.requested_by.name};
      to proceed this maintenance must be confirmed on the cluster dashboard:
      #{cluster_dashboard_url}.
    EOF
  end

  def confirm_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} confirmed by
      #{window.confirmed_by.name}; this maintenance has been scheduled from
      #{requested_start} until #{expected_end}.
    EOF
  end

  def mandate_comment
    <<~EOF
      Maintenance for #{associated_model.name} has been scheduled from
      #{requested_start} until #{expected_end} by #{window.confirmed_by.name};
      this maintenance is mandatory.
    EOF
  end

  def cancel_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} cancelled by
      #{window.cancelled_by.name}.
    EOF
  end

  def reject_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} rejected by
      #{window.rejected_by.name}.
    EOF
  end

  def end_comment
    "Maintenance of #{associated_model.name} ended by #{window.ended_by.name}."
  end

  def auto_expire_comment
    <<~EOF
      Request for maintenance of #{associated_model.name} was not confirmed
      before requested start date of #{requested_start}; this maintenance can
      no longer occur as requested and must be rescheduled and confirmed on the
      cluster dashboard: #{cluster_dashboard_url}.
    EOF
  end

  def auto_start_comment
    <<~EOF
      Scheduled maintenance of #{associated_model.name} has automatically
      started; this #{associated_model.readable_model_name} is now under
      maintenance until #{expected_end}.
    EOF
  end

  def auto_end_comment
    <<~EOF
      Scheduled maintenance of #{associated_model.name} has automatically
      ended.
    EOF
  end

  def add_rt_ticket_correspondence(text)
    window.case.add_rt_ticket_correspondence(text)
  end

  def cluster_dashboard_url
    cluster_maintenance_windows_url(window.associated_cluster)
  end

  def requested_start
    window.requested_start.to_formatted_s(:short)
  end

  def expected_end
    window.expected_end.to_formatted_s(:short)
  end
end
