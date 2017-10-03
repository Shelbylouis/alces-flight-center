
require 'exceptions'

class RequestTrackerInterface
  RT_API_ENDPOINT = 'http://gateway.alces-software.com:5556/rt/REST/1.0/'
  NEW_TICKET_PATH = 'ticket/new'

  Ticket = Struct.new(:id)

  attr_reader :username, :password

  def initialize
    @username = ENV.fetch('RT_USERNAME')
    @password = ENV.fetch('RT_PASSWORD')
  end

  def create_ticket(requestor_email:, subject:, text:)
    content = new_ticket_request_content(
      requestor_email: requestor_email,
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
    url = URI.join(RT_API_ENDPOINT, path)
    HTTP.timeout(write: 2, connect: 5, read: 10).post(
      url,
      params: {user: username, pass: password},
      body: "content=#{content}"
    ).tap do |r|
      unless r.status.success?
        raise UnexpectedRtApiResponseException, r.body
      end
    end
  end

  def new_ticket_request_content(requestor_email:, subject:, text:)
    Utils.rt_format({
      Queue: 'Support',
      Requestor: requestor_email,
      Subject: subject,
      Text: text
    })
  end
end
