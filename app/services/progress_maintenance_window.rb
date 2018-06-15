
ProgressMaintenanceWindow = Struct.new(:window) do
  def progress
    maybe_send_maintenance_ending_soon_email
    if required_transition_event
      transition_state(required_transition_event)
    else
      unprogressed_message
    end
  end

  private

  delegate :confirmed?, :started?, to: :window

  def required_transition_event
    @required_transition_event ||=
      if end_time_passed? && started?
        :auto_end
      elsif start_time_passed? && confirmed?
        :auto_start
      elsif start_time_passed? && not_yet_confirmed?
        :auto_expire
      end
  end

  def end_time_passed?
    window.expected_end.past?
  end

  def start_time_passed?
    window.requested_start.past?
  end

  def not_yet_confirmed?
    window.new? || window.requested?
  end

  def unprogressed_message
    progression_message("remains #{window.state}")
  end

  def transition_state(event)
    old_state = window.state
    window.update!(state_event: event)
    new_state = window.state
    progression_message("#{old_state} -> #{new_state}")
  end

  def progression_message(message)
    "Maintenance window #{window.id} (#{window_details}): #{message}"
  end

  def window_details
    "#{window.associated_model.name} | #{start_date} - #{end_date}"
  end

  def start_date
    format_datetime(window.requested_start)
  end

  def end_date
    format_datetime(window.expected_end)
  end

  def format_datetime(datetime)
    datetime.to_formatted_s(:short)
  end

  def maybe_send_maintenance_ending_soon_email
    if should_send_maintenance_ending_soon_email?
      send_maintenance_ending_soon_email
    end
  end

  def should_send_maintenance_ending_soon_email?
    email_not_sent_yet? && less_than_an_hour_left? && started?
  end

  def email_not_sent_yet?
    !window.maintenance_ending_soon_email_sent
  end

  def less_than_an_hour_left?
    1.hour.from_now >= window.expected_end
  end

  def send_maintenance_ending_soon_email
    CaseMailer.maintenance_ending_soon(
      window,
      <<-EOF.squish
        Maintenance for #{window.associated_model.name} is scheduled to
        end at #{window.expected_end.to_formatted_s(:short)}. You have
        less than an hour to make any final changes.
      EOF
    )
  end
end
