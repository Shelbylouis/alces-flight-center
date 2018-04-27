class SetCaseStatesFromRt < ActiveRecord::DataMigration
  def up
    Case.all.each do |c|
      c.update_ticket_status!
      if c.last_known_ticket_status
        c.state = state_from_rt_status(c.last_known_ticket_status)
        c.save!
      end
    end
  end

  private

  def state_from_rt_status(rt)
    case rt
    when 'new', 'open', 'stalled'
      :open
    when 'resolved', 'rejected', 'deleted'
      return :resolved
    end
  end
end
