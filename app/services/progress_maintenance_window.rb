
ProgressMaintenanceWindow = Struct.new(:window) do
  def progress
    progress_if_needed || unprogressed_message
  end

  private

  delegate :confirmed?, :started?, to: :window

  def progress_if_needed
    if end_time_passed? && started?
      progress_state(:ended)
    elsif start_time_passed?
      start_or_expire_if_unstarted
    end
  end

  def end_time_passed?
    window.requested_end.past?
  end

  def start_time_passed?
    window.requested_start.past?
  end

  def start_or_expire_if_unstarted
    if confirmed?
      progress_state(:started)
    elsif unconfirmed?
      progress_state(:expired)
    end
  end

  def unconfirmed?
    window.new? || window.requested?
  end

  def unprogressed_message
    progression_message("remains #{window.state}")
  end

  def progress_state(new_state)
    old_state = window.state
    window.update!(state: new_state)
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