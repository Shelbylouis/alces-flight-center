
class RequestTrackerInterface
  RT_API_ENDPOINT = 'http://helpdesk.alces-software.com/rt/REST/1.0/'
  NEW_TICKET_PATH = 'ticket/new'

  attr_reader :username, :password

  def initialize
    @username = ENV.fetch('RT_USERNAME')
    @password = ENV.fetch('RT_PASSWORD')
  end

  def create_ticket(requestor_email:, subject:, text:)
    url = URI.join(RT_API_ENDPOINT, NEW_TICKET_PATH)
    content = new_ticket_request_content(
      requestor_email: requestor_email,
      subject: subject,
      text: text
    )

    HTTP.post(
      url,
      params: {user: username, pass: password},
      body: "content=#{content}"
    )
  end

  private

  def new_ticket_request_content(requestor_email:, subject:, text:)
    parameters = {
        Queue: 'Support',
        Requestor: requestor_email,
        Subject: subject,
        # Multiline text must have each new line prefixed with a space.
        Text: text.gsub("\n", "\n "),
    }
    parameters.map { |pair| pair.join(': ') }.join("\n")
  end
end
