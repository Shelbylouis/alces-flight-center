require 'rails_helper'

RSpec.shared_examples 'Request Tracker interface' do
  subject { described_class.new }

  let :new_ticket_params do
    {
      requestor_email: 'test@example.com',
      cc: ['some.user@example.com]', 'another.user@example.com'],
      subject: 'Alces Flight Center test ticket - please delete',
      text: <<-EOF.strip_heredoc
            Testing
            multiline
            text
            works
      EOF
    }
  end

  describe '#create_ticket [interface]' do
    it 'creates a ticket and returns object with id' do
      VCR.use_cassette(VcrCassettes::RT_CREATE_TICKET) do
        ticket = subject.create_ticket(new_ticket_params)

        # All tickets now have IDs greater than this.
        expect(ticket.id).to be > 10000
      end
    end
  end

  describe '#show_ticket [interface]' do
    it 'returns ticket data including status' do
      VCR.use_cassette(VcrCassettes::RT_SHOW_TICKET) do
        ticket = subject.show_ticket(10003)

        # Ticket 10003 happens to be a real ticket which is 'resolved' (see
        # http://helpdesk.alces-software.com/rt/REST/1.0/ticket/10003), and we
        # also want fake interface to give 'resolved' status by default, so
        # this expectation should pass for both implementations.
        expect(ticket.status).to eq 'resolved'
      end
    end
  end
end

RSpec.describe RequestTrackerInterface do
  include_context 'Request Tracker interface'

  describe '#create_ticket' do
    let :bad_response_body { 'Oh no, things went wrong' }

    it 'includes correct request body' do
      expect_any_instance_of(HTTP::Client).to receive(:post).with(
        any_args,
        hash_including(
          body: 'content=' + Utils.rt_format(
            Queue: 'Support',
            Requestor: new_ticket_params[:requestor_email],
            Cc: new_ticket_params[:cc].join(','),
            Subject: new_ticket_params[:subject],
            Text: new_ticket_params[:text],
          )
        )
      ).and_call_original

      VCR.use_cassette(VcrCassettes::RT_CREATE_TICKET) do
        subject.create_ticket(new_ticket_params)
      end
    end

    it 'raises when API responds with an unexpected status' do
      stub_request(
        :any, /#{subject.api_endpoint}/
      ).to_return(
        status: 418,
        body: bad_response_body
      )

      VCR.turned_off do
        expect do
          subject.create_ticket(new_ticket_params)
        end.to raise_error(
          UnexpectedRtApiResponseException, bad_response_body
        )
      end
    end

    it 'raises when API responds with an unexpected body format' do
      stub_request(
        :any, /#{subject.api_endpoint}/
      ).to_return(
        body: bad_response_body
      )

      VCR.turned_off do
        expect do
          subject.create_ticket(new_ticket_params)
        end.to raise_error(
          UnexpectedRtApiResponseException, bad_response_body
        )
      end
    end
  end
end

RSpec.describe FakeRequestTrackerInterface do
  include_context 'Request Tracker interface'

  describe '#create_ticket' do
    it 'produces tickets with incrementing IDs' do
      # Mock that we have a Case with the current maximum rt ticket id.
      max_rt_ticket_id = 10001
      allow(Case).to receive(:maximum).and_return(max_rt_ticket_id)

      new_rt_ticket_id = subject.create_ticket(new_ticket_params).id
      expect(new_rt_ticket_id).to eq(max_rt_ticket_id + 1)
    end
  end
end
