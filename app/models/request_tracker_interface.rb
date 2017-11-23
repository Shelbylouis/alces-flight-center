
require 'exceptions'

class RequestTrackerInterface
  NEW_TICKET_PATH = 'ticket/new'.freeze

  Ticket = Struct.new(:id)

  attr_reader :username, :password, :api_endpoint

  def initialize
    @username = ENV.fetch('RT_USERNAME')
    @password = ENV.fetch('RT_PASSWORD')

    api_host = ENV.fetch('RT_API_HOST')
    @api_endpoint = "http://#{api_host}/rt/REST/1.0/"
  end

  def create_ticket(requestor_email:, cc:, subject:, text:)
    content = new_ticket_request_content(
      requestor_email: requestor_email,
      cc: cc,
      subject: subject,
      text: text
    )

    response = api_request(NEW_TICKET_PATH, body: "content=#{content}")

    ticket_id_regex = /Ticket (\d{5,}) created./
    response_match = response.to_s.match(ticket_id_regex)
    raise UnexpectedRtApiResponseException, response.body unless response_match

    id = response_match[1].to_i
    Ticket.new(id)
  end

  def show_ticket(id)
    path = "ticket/#{id}/show"
    response = api_request(path)
    response_text = response.to_s

    # Rudimentary check that response is in expected format.
    response_appears_correct = response_text.match?(/id: ticket\//)
    unless response_appears_correct
      raise UnexpectedRtApiResponseException, response.body
    end

    # Ticket data is sandwiched between blank lines at both ends.
    ticket_data = response_text.split("\n\n").second

    ticket_struct_from_data(ticket_data).tap do |ticket|
      # Set ID in ticket to ID passed; without this it is returned in
      # `"ticket/12345"` format from RT. Which is not very helpful.
      ticket.id = id
    end
  end

  private

  def api_request(path, body: nil)
    url = URI.join(api_endpoint, path)
    HTTP.timeout(write: 2, connect: 5, read: 10).post(
      url,
      params: { user: username, pass: password },
      body: body
    ).tap do |r|
      raise UnexpectedRtApiResponseException, r.body unless r.status.success?
    end
  end

  def new_ticket_request_content(requestor_email:, cc:, subject:, text:)
    CGI.escape(
      Utils.rt_format(
        Queue: 'Support',
        Requestor: requestor_email,
        Cc: cc.join(','),
        Subject: subject,
        Text: text
      )
    )
  end

  def ticket_struct_from_data(ticket_data)
    ticket_data.lines.map do |line|
      line.split(':').map(&:strip)
    end.map do |property, value|
      # Create nice method name from ticket property name.
      property_access_method = property.downcase.gsub('-', '_').to_sym
      [property_access_method, value]
    end.to_h.to_struct
  end
end
