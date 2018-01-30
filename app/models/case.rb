class Case < ApplicationRecord
  include AdminConfig::Case

  COMPLETED_TICKET_STATUSES = [
    'resolved',
    'rejected',
    'deleted',
  ]

  TICKET_STATUSES = (
    [
      'new',
      'open',
      'stalled',
    ] + COMPLETED_TICKET_STATUSES
  ).freeze

  belongs_to :issue
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :service, required: false
  belongs_to :user
  has_one :credit_charge, required: false
  has_many :maintenance_windows

  delegate :category, :chargeable, to: :issue
  delegate :site, to: :cluster, allow_nil: true

  validates :details, presence: true
  validates :token, presence: true
  validates :rt_ticket_id, presence: true, uniqueness: true

  validates :last_known_ticket_status,
    presence: true,
    inclusion: {in: TICKET_STATUSES}

  validates_with Validator

  after_initialize :assign_cluster_if_necessary
  after_initialize :generate_token_if_necessary

  # This must occur after `assign_cluster_if_necessary`, so that Cluster is set
  # if this is possible but it was not explicitly passed.
  before_validation :create_rt_ticket, on: :create

  def self.request_tracker
    # Note: `rt_interface_class` is a string which we `constantize`, rather
    # than a constant directly, otherwise Rails autoloading in development
    # could leave us holding a reference to an outdated version of the class,
    # which would then cause things to blow up (e.g. see
    # https://stackoverflow.com/a/23008837).
    @rt ||= Rails.configuration.rt_interface_class.constantize.new
  end

  def mailto_url
    support_email = 'support@alces-software.com'
    "mailto:#{support_email}?subject=#{rt_email_subject}"
  end

  def open
    !archived
  end

  def update_ticket_status!
    return if ticket_completed?

    self.last_known_ticket_status = associated_rt_ticket.status
    save!
  end

  def requires_credit_charge?
    return false if credit_charge
    credit_charge_allowed?
  end

  def credit_charge_allowed?
    ticket_completed? && chargeable
  end

  def request_maintenance_window!(requestor:)
    RequestMaintenanceWindow.new(case_id: id, user: requestor).run
  end

  def add_rt_ticket_correspondence(text)
    rt.add_ticket_correspondence(id: rt_ticket_id, text: text)
  end

  def associated_model
    component || service || cluster
  end

  def associated_model_type
    associated_model.readable_model_name
  end

  private

  def create_rt_ticket
    return unless cluster

    ticket = rt.create_ticket(
      requestor_email: requestor_email,
      cc: cc_emails,
      subject: rt_ticket_subject,
      text: rt_ticket_text
    )

    self.rt_ticket_id = ticket.id
  end

  def assign_cluster_if_necessary
    return if cluster
    self.cluster = component.cluster if component
    self.cluster = service.cluster if service
  end

  def ticket_completed?
    COMPLETED_TICKET_STATUSES.include?(last_known_ticket_status)
  end

  def associated_rt_ticket
    rt.show_ticket(rt_ticket_id)
  end

  def rt
    self.class.request_tracker
  end

  def requestor_email
    user.email
  end

  def cc_emails
    site.all_contacts
      .reject { |contact| contact.email == requestor_email }
      .map(&:email)
  end

  def rt_email_subject
    rt_email_identifier = "[helpdesk.alces-software.com ##{rt_ticket_id}]"
    "RE: #{rt_email_identifier} #{rt_ticket_subject}"
  end

  def rt_ticket_subject
    "Alces Flight Center ticket: #{cluster.name} - #{issue.name} [#{token}]"
  end

  # We generate a short random token to identify each ticket within email
  # clients and RT. Without this, similar but distinct tickets can be hard to
  # distinguish in RT as they will have identical subjects, and many email
  # clients will also collapse different tickets into the same thread due to
  # their similar subjects (see
  # https://github.com/alces-software/alces-flight-center/issues/41#issuecomment-361307971).
  def generate_token_if_necessary
    self.token ||= Utils.generate_password(length: 5).upcase
  end

  def rt_ticket_text
    properties = {
      Requestor: user.name,
      Cluster: cluster.name,
      Category: category&.name,
      'Issue': issue.name,
      'Associated component': component&.name,
      'Associated service': service&.name,
      Details: details,
    }.reject { |_k, v| v.nil? }

    # Ticket text does not need to be in this format, it is just text, but this
    # is readable and an adequate format for now.
    Utils.rt_format(properties)
  end
end
