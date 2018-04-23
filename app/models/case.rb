class Case < ApplicationRecord
  include AdminConfig::Case

  COMPLETED_RT_TICKET_STATUSES = [
    'resolved',
    'rejected',
    'deleted',
  ]

  RT_TICKET_STATUSES = (
    [
      'new',
      'open',
      'stalled',
    ] + COMPLETED_RT_TICKET_STATUSES
  ).freeze

  belongs_to :issue
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :service, required: false
  belongs_to :user
  has_one :credit_charge, required: false
  has_many :maintenance_windows
  has_and_belongs_to_many :log
  has_many :case_comments

  has_many :case_state_transitions
  alias_attribute :transitions, :case_state_transitions

  delegate :category, :chargeable, to: :issue
  delegate :site, to: :cluster, allow_nil: true

  state_machine initial: :open do
    audit_trail context: [:requesting_user], initial: false

    state :open  # Open case, still work to do
    state :resolved  # Has been resolved but not yet accounted for commercially
    state :archived  # Has been accounted for commercially, nothing more to do

    event(:resolve) { transition open: :resolved }  # Resolved cases cannot be reopened
    event(:archive) { transition resolved: :archived }

  end

  validates :details, presence: true
  validates :token, presence: true
  validates :subject, presence: true
  validates :rt_ticket_id, uniqueness: true, if: :rt_ticket_id
  validates :fields, presence: true

  validates :tier_level,
    presence: true,
    numericality: {
      only_integer: true,
      # Cases cannot be created for Tier of level 0; Tier 0 support is just
      # providing access to documentation without any action needing to be
      # taken by Alces admins.
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 3,
    }

  validates :last_known_ticket_status,
    inclusion: {in: TICKET_STATUSES}

  # Only validate Issue relationship on create, as the Issue must be allowed
  # given the associated model for this Case at the point when the Case is
  # created, but the associated model's `support_type` (or less commonly the
  # Issue's) may later change and become incompatible with this Issue, but this
  # should not invalidate a Case which was allowed at the point when it was
  # created.
  validates_with IssueValidator, on: :create

  validates_with AssociatedModelValidator

  after_initialize :assign_cluster_if_necessary
  after_initialize :generate_token, on: :create

  before_validation :assign_default_subject_if_unset

  after_create :send_new_case_email

  scope :active, -> { where(archived: false) }

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
    "mailto:#{support_email}?subject=#{email_reply_subject}"
  end

  def open?
    self.state == 'open'
  end

  def archived?
    self.state == 'resolved' || self.state == 'archived'
  end

  def update_ticket_status!
    return unless incomplete_rt_ticket?
    self.last_known_ticket_status = associated_rt_ticket.status
    if ticket_completed?
      self.completed_at = DateTime.now.utc
    end
    save!
  end

  def requires_credit_charge?
    return false if credit_charge
    credit_charge_allowed?
  end

  def credit_charge_allowed?
    ticket_completed? && chargeable
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

  def ticket_completed?
    COMPLETED_RT_TICKET_STATUSES.include?(last_known_ticket_status)
  end

  def events
    (
      case_comments.select(&:created_at) +  # Note that CasesController#show
        # creates a new, unsaved CaseComment (because the view needs it)
        # so there will be one included in this set without a created_at
        # date. We clearly don't want to include that in the events stream.
      maintenance_windows.map(&:transitions).flatten.select(&:event)
    ).sort_by(&:created_at)
  end

  def email_recipients
    site.all_contacts
        .map(&:email)
  end

  def email_reply_subject
    "RE: #{email_subject}"
  end

  def email_subject
    "#{email_identifier} #{ticket_subject}"
  end

  def email_identifier
    if rt_ticket_id
      "[helpdesk.alces-software.com ##{rt_ticket_id}]"
    else
      "[Alces Flight Center ##{id}]"
    end
  end

  def ticket_subject
    # NOTE: If the format used here ever changes then this may cause emails
    # sent using the `mailto` links for existing Cases to not be threaded with
    # previous emails related to that Case (see
    # https://github.com/alces-software/alces-flight-center/issues/37#issuecomment-358948462
    # for an explanation). If we want to change this format and avoid this
    # consequence then a solution would be to first add a new field for this
    # whole string, and save and use the existing format for existing Cases.
    "#{cluster.name}: #{subject} [#{token}]"
  end

  def rt_ticket_text
    # Ticket text does not need to be in this format, it is just text, but this
    # is readable and an adequate format for now.
    Utils.rt_format(case_properties)
  end

  private

  # Picked up by state_machines-audit_trail due to `context` setting above, and
  # used to automatically set user who instigated the transition in created
  # CaseStateTransition.
  # Refer to
  # https://github.com/state-machines/state_machines-audit_trail#example-5---store-advanced-method-results.
  def requesting_user(transition)
    transition.args&.first
  end

  def incomplete_rt_ticket?
    rt_ticket_id && (!ticket_completed? || !self.completed_at)
  end

  def assign_cluster_if_necessary
    return if cluster
    self.cluster = component.cluster if component
    self.cluster = service.cluster if service
  end

  def assign_default_subject_if_unset
    self.subject ||= issue.default_subject
  end

  def associated_rt_ticket
    if rt_ticket_id
      @associated_ticket ||= rt.show_ticket(rt_ticket_id)
    else
      nil
    end
  end

  def rt
    self.class.request_tracker
  end

  def requestor_email
    user.email
  end

  # We generate a short random token to identify each ticket within email
  # clients and RT. Without this, similar but distinct tickets can be hard to
  # distinguish in RT as they will have identical subjects, and many email
  # clients will also collapse different tickets into the same thread due to
  # their similar subjects (see
  # https://github.com/alces-software/alces-flight-center/issues/41#issuecomment-361307971).
  #
  # We generate this token with alternating letters and digits to minimize the
  # possibility of recognisable, and particularly offensive, words being
  # generated (see https://alces.slack.com/archives/C72GT476Y/p1518440238000090
  # and https://alces.slack.com/archives/C72GT476Y/p1518529346000098)
  def generate_token
    length = 5
    letters = ('A'..'Z').to_a
    digits = (0..9).to_a
    self.token ||=
      (0...length).map do |position|
        (position.even? ? letters : digits).sample
      end.join
  end


  def case_properties
    {
      Requestor: user.name,
      Cluster: cluster.name,
      Category: category&.name,
      'Issue': issue.name,
      'Associated component': component&.name,
      'Associated service': service&.name,
      Details: details,
    }.reject { |_k, v| v.nil? }
  end

  def send_new_case_email
    CaseMailer.new_case(self).deliver_later
  end
end
