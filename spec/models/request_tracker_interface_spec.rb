require 'rails_helper'

RSpec.describe RequestTrackerInterface, type: :model do
  subject { RequestTrackerInterface.new }

  describe 'create_ticket' do
    it 'creates a ticket and returns object with id' do
      VCR.use_cassette('rt_create_ticket', re_record_interval: 7.days) do
        ticket = subject.create_ticket(
          requestor_email: 'test@example.com',
          subject: 'Supportware test ticket - please delete',
          text: <<-EOF.strip_heredoc
            Testing
            multiline
            text
            works
          EOF
        )

        # All tickets now have IDs greater than this.
        expect(ticket.id).to be > 10000
      end
    end
  end
end
