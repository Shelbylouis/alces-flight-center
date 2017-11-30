require 'rails_helper'

RSpec.shared_examples 'Request Tracker interface' do
  let :rt_interface { described_class.new }

  let :new_ticket_params do
    {
      requestor_email: 'test@example.com',
      cc: ['some.user@example.com]', 'another.user@example.com'],
      subject: 'Alces Flight Center test ticket - please delete',
      text: <<-EOF.strip_heredoc
            Testing
            multiline
            text
            with semicolon ;
            works
      EOF
    }
  end

  let! :created_ticket do
    VCR.use_cassette(VcrCassettes::RT_CREATE_TICKET) do
      rt_interface.create_ticket(new_ticket_params)
    end
  end

  describe '#create_ticket [interface]' do
    subject { created_ticket }

    it 'creates a ticket and returns object with id' do
      # All tickets now have IDs greater than this.
      expect(subject.id).to be > 10000
    end
  end

  describe '#add_ticket_correspondence [interface]' do
    subject do
      rt_interface.add_ticket_correspondence(
        id: created_ticket.id,
        text: 'Alces Flight Center test comment'
      )
    end

    it 'returns RT success response' do
      VCR.use_cassette(VcrCassettes::RT_ADD_TICKET_CORRESPONDENCE) do
        expect(subject).to include '# Message recorded'
      end
    end
  end

  describe '#show_ticket [interface]' do
    subject { rt_interface.show_ticket(10003) }

    it 'returns ticket data including status' do
      VCR.use_cassette(VcrCassettes::RT_SHOW_TICKET) do
        # Ticket 10003 happens to be a real ticket which is 'resolved' (see
        # http://helpdesk.alces-software.com/rt/REST/1.0/ticket/10003), and we
        # also want fake interface to give 'resolved' status in this case, so
        # this expectation should pass for both implementations.
        expect(subject.status).to eq 'resolved'
      end
    end

    it 'returns ID in ticket as integer' do
      VCR.use_cassette(VcrCassettes::RT_SHOW_TICKET) do
        expect(subject.id).to eq 10003
      end
    end
  end
end

RSpec.describe RequestTrackerInterface do
  include_context 'Request Tracker interface'

  RSpec.shared_examples 'error_handling' do
    let :bad_response_body { 'Oh no, things went wrong' }

    it 'raises when API responds with an unexpected status' do
      stub_request(
        :any, /#{rt_interface.api_endpoint}/
      ).to_return(
        status: 418,
        body: bad_response_body
      )

      VCR.turned_off do
        expect { subject }.to raise_error(
          UnexpectedRtApiResponseException, bad_response_body
        )
      end
    end

    it 'raises when API responds with an unexpected body format' do
      stub_request(
        :any, /#{rt_interface.api_endpoint}/
      ).to_return(
        body: bad_response_body
      )

      VCR.turned_off do
        expect { subject }.to raise_error(
          UnexpectedRtApiResponseException, bad_response_body
        )
      end
    end
  end

  describe '#create_ticket' do
    subject { rt_interface.create_ticket(new_ticket_params) }

    include_examples 'error_handling'

    it 'includes correct request body' do
      expect_any_instance_of(HTTP::Client).to receive(:post).with(
        any_args,
        hash_including(
          body: 'content=' + CGI.escape(
            Utils.rt_format(
              Queue: 'Support',
              Requestor: new_ticket_params[:requestor_email],
              Cc: new_ticket_params[:cc].join(','),
              Subject: new_ticket_params[:subject],
              Text: new_ticket_params[:text],
            )
          )
        )
      ).and_call_original

      VCR.use_cassette(VcrCassettes::RT_CREATE_TICKET) { subject }
    end
  end

  describe '#add_ticket_correspondence' do
    subject do
      rt_interface.add_ticket_correspondence(
        id: created_ticket.id,
        text: 'Alces Flight Center test comment'
      )
    end

    include_examples 'error_handling'
  end

  describe '#show_ticket' do
    subject { rt_interface.show_ticket(10003) }

    include_examples 'error_handling'
  end
end

RSpec.describe FakeRequestTrackerInterface do
  include_context 'Request Tracker interface'

  describe '#create_ticket' do
    subject { rt_interface.create_ticket(new_ticket_params) }

    it 'produces tickets with incrementing IDs' do
      # Mock that we have a Case with the current maximum rt ticket id.
      max_rt_ticket_id = 10001
      allow(Case).to receive(:maximum).and_return(max_rt_ticket_id)

      new_rt_ticket_id = subject.id
      expect(new_rt_ticket_id).to eq(max_rt_ticket_id + 1)
    end
  end

  describe '#show_ticket' do
    # Use simple, predictable scheme to simulate mix of open and completed
    # tickets in development.
    it 'gives `resolved` status when ticket ID is odd' do
      expect(rt_interface.show_ticket(10001).status).to eq('resolved')
    end

    it 'gives `open` status when ticket ID is even' do
      expect(rt_interface.show_ticket(10002).status).to eq('open')
    end
  end
end
