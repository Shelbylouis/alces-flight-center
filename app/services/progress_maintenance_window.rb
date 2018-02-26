
ProgressMaintenanceWindow = Struct.new(:window) do
  def progress
    progress_if_needed || unprogressed_message
  end

  private

  delegate :confirmed?, :started?, to: :window

  def progress_if_needed
    if required_transition_event
      transition_state(required_transition_event)
    end
  end

  def required_transition_event
    @required_transition_event ||=
      if end_time_passed? && started?
        :end
      elsif start_time_passed? && confirmed?
        :start
      elsif start_time_passed? && not_yet_confirmed?
        :expire
      end
  end

  def end_time_passed?
    window.requested_end.past?
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
    format_datetime(window.requested_end)
  end

  def format_datetime(datetime)
    datetime.to_formatted_s(:short)
  end
end
