class Case < ApplicationRecord
  # The status of a Case is purely for user's benefits, so they can archive
  # (hide) cases they no longer wish to be prominent within the UI; this is
  # unrelated to what the status of the corresponding ticket is within the
  # Alces rt system.
  STATUSES = ['open', 'archived'].freeze

  belongs_to :case_category
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :user

  validates :details, presence: true
  validates :rt_ticket_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }, presence: true

  before_validation :create_rt_ticket, on: :create

  def create_rt_ticket
    ticket = request_tracker.create_ticket(
      requestor_email: user.email,
      subject: rt_ticket_subject,
      text: rt_ticket_text
    )

    self.rt_ticket_id = ticket.id
  end

  def mailto_url
    support_email = 'support@alces-software.com'
    subject = URI.escape(rt_email_subject)
    "mailto:#{support_email}?subject=#{subject}"
  end

  private

  def request_tracker
    # Note: `rt_interface_class` is a string which we `constantize`, rather
    # than a constant directly, otherwise Rails autoloading in development
    # could leave us holding a reference to an outdated version of the class,
    # which would then cause things to blow up (e.g. see
    # https://stackoverflow.com/a/23008837).
    @rt ||= Rails.configuration.rt_interface_class.constantize.new
  end

  def rt_email_subject
    rt_email_identifier = "[helpdesk.alces-software.com ##{rt_ticket_id}]"
    "RE: #{rt_email_identifier} #{rt_ticket_subject}"
  end

  def rt_ticket_subject
    "Supportware ticket: #{cluster.name} - #{case_category.name}"
  end

  def rt_ticket_text
    properties = {
      Cluster: cluster.name,
      'Case category': case_category.name,
      'Associated component': component&.name,
      Details: details
    }.reject { |k,v| v.nil? }

    # Ticket text does not need to be in this format, it is just text, but this
    # is readable and an adequate format for now.
    Utils.rt_format(properties)
  end
end
