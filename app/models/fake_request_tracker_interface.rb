
# This should match the API of RequestTrackerInterface but make no actual
# requests to the real rt instance; for use in development.
class FakeRequestTrackerInterface
  def create_ticket(requestor_email:, subject:, text:)
    RequestTrackerInterface::Ticket.new(10001)
  end
end
