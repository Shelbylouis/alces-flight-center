
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

    response = api_request(NEW_TICKET_PATH, content: content)

    ticket_id_regex = /Ticket (\d{5,}) created./
    response_match = response.to_s.match(ticket_id_regex)
    raise UnexpectedRtApiResponseException, response.body unless response_match

    id = response_match[1].to_i
    Ticket.new(id)
  end

  private

  def api_request(path, content:)
    url = URI.join(api_endpoint, path)
    HTTP.timeout(write: 2, connect: 5, read: 10).post(
      url,
      params: { user: username, pass: password },
      body: "content=#{content}"
    ).tap do |r|
      raise UnexpectedRtApiResponseException, r.body unless r.status.success?
    end
  end

  def new_ticket_request_content(requestor_email:, cc:, subject:, text:)
    Utils.rt_format(
      Queue: 'Support',
      Requestor: requestor_email,
      Cc: cc,
      Subject: subject,
      Text: text
    )
  end
end
