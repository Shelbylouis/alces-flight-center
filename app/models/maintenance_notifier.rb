
MaintenanceNotifier = Struct.new(:window) do
  def add_transition_comment(event)
    comment_method = "#{event}_comment".to_sym
    comment = send(comment_method).squish
    send_email(comment)
  end

  private

  def associated_model_names
    window.decorate.associated_model_names
  end

  delegate :cluster_maintenance_windows_url,
    to: 'Rails.application.routes.url_helpers'

  def request_comment
    <<-EOF
      Maintenance requested for #{associated_model_names} from
      #{requested_start} until #{expected_end} by #{window.requested_by.name};
      to proceed this maintenance must be confirmed on the cluster dashboard:
      #{cluster_dashboard_url}.
    EOF
  end

  def confirm_comment
    <<~EOF
      Request for maintenance of #{associated_model_names} confirmed by
      #{window.confirmed_by.name}; this maintenance has been scheduled from
      #{requested_start} until #{expected_end}.
    EOF
  end

  def mandate_comment
    <<~EOF
      Maintenance for #{associated_model_names} has been scheduled from
      #{requested_start} until #{expected_end} by #{window.confirmed_by.name};
      this maintenance is mandatory.
    EOF
  end

  def cancel_comment
    <<~EOF
      Request for maintenance of #{associated_model_names} cancelled by
      #{window.cancelled_by.name}.
    EOF
  end

  def reject_comment
    <<~EOF
      Request for maintenance of #{associated_model_names} rejected by
      #{window.rejected_by.name}.
    EOF
  end

  def extend_duration_comment
    <<~EOF
      #{window.user_facing_state.capitalize} maintenance of
      #{associated_model_names} has been extended, they will now be under 
      maintenance from #{requested_start} until #{expected_end}.
    EOF
  end

  def end_comment
    "Maintenance of #{associated_model_names} ended by #{window.ended_by.name}."
  end

  def auto_expire_comment
    <<~EOF
      Request for maintenance of #{associated_model_names} was not confirmed
      before requested start date of #{requested_start}; this maintenance can
      no longer occur as requested and must be rescheduled and confirmed on the
      cluster dashboard: #{cluster_dashboard_url}.
    EOF
  end

  def auto_start_comment
    <<~EOF
      Scheduled maintenance of #{associated_model_names} has automatically
      started; they are now under
      maintenance until #{expected_end}.
    EOF
  end

  def auto_end_comment
    <<~EOF
      Scheduled maintenance of #{associated_model_names} has automatically
      ended.
    EOF
  end

  def send_email(text)
    CaseMailer.maintenance_state_transition(window.case, text).deliver_later
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
