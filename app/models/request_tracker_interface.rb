
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
    body = request_body(
      Queue: 'Support',
      Requestor: requestor_email,
      Cc: cc.join(','),
      Subject: subject,
      Text: text
    )

    response = api_request(NEW_TICKET_PATH, body: body)

    ticket_id = validate_response!(
      response,
      /Ticket (\d{5,}) created./
    )[1].to_i

    Ticket.new(ticket_id)
  end

  def add_ticket_correspondence(id:, text:)
    path = "ticket/#{id}/comment"
    body = request_body(
      id: id,
      Action: 'correspond',
      Text: text
    )

    response = api_request(path, body: body)
    validate_response!(response, 'Message recorded')

    # Just return response body at the moment so can check this looks correct,
    # as apart from success message no useful information is returned.
    response.to_s
  end

  def show_ticket(id)
    path = "ticket/#{id}/show"
    response = api_request(path)
    validate_response!(response, /id: ticket\//)

    # Ticket data is sandwiched between blank lines at both ends.
    ticket_data = response.to_s.split("\n\n").second

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

  def request_body(request_params)
    content = CGI.escape(Utils.rt_format(request_params))
    "content=#{content}"
  end

  def validate_response!(response, regex)
    response.to_s.match(regex).tap do |response_match|
      raise UnexpectedRtApiResponseException, response.body unless response_match
    end
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
