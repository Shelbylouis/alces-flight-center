
ProgressMaintenanceWindow = Struct.new(:window) do
  def progress
    if end_time_passed? && started?
      window.end!
    elsif start_time_passed?
      start_or_expire_if_unstarted
    end
  end

  private

  delegate :confirmed?, :started?, to: :window

  def end_time_passed?
    window.requested_end.past?
  end

  def start_time_passed?
    window.requested_start.past?
  end

  def start_or_expire_if_unstarted
    if confirmed?
      window.start!
    elsif unconfirmed?
      window.expire!
    end
  end

  def unconfirmed?
    window.new? || window.requested?
  end
end
