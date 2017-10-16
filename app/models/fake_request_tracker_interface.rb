
# This should match the API of RequestTrackerInterface but make no actual
# requests to the real rt instance; for use in development.
class FakeRequestTrackerInterface
  def create_ticket(requestor_email:, cc:, subject:, text:)
    current_max_rt_ticket_id = Case.maximum(:rt_ticket_id) || 10000
    RequestTrackerInterface::Ticket.new(current_max_rt_ticket_id + 1)
  end
end
