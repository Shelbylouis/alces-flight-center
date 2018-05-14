class Case < ApplicationRecord
  include AdminConfig::Case

  default_scope { order(created_at: :desc) }

  # @deprecated - to be removed in next release
  COMPLETED_RT_TICKET_STATUSES = [
    'resolved',
    'rejected',
    'deleted',
  ]

  # @deprecated - to be removed in next release
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
  belongs_to :assignee, class_name: 'User', required: false

  has_many :maintenance_windows
  has_and_belongs_to_many :log
  has_many :case_comments
  has_one :change_motd_request, required: false

  has_many :case_state_transitions
  alias_attribute :transitions, :case_state_transitions

  delegate :category, :chargeable, to: :issue
  delegate :site, to: :cluster, allow_nil: true

  state_machine initial: :open do
    audit_trail context: [:requesting_user], initial: false

    state :open  # Open case, still work to do
    state :resolved  # Has been resolved but not yet accounted for commercially
    state :closed  # Has been accounted for commercially, nothing more to do

    event(:resolve) { transition open: :resolved }  # Resolved cases cannot be reopened
    event(:close) { transition resolved: :closed }

  end

  audited only: [:assignee_id, :time_worked, :credit_charge], on: [ :update ]

  # XXX Remove if: display_id when we can do so
  validates :display_id, uniqueness: true, if: :display_id

  # XXX We want to enable this validation when we've migrated production over -
  # otherwise historical migrations will fail :(
  #validate :has_display_id_when_saved

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

  validates :time_worked, numericality: {
      greater_than_or_equal_to: 0,
      only_integer: true  # We store time worked as integer minutes.
  }

  validate :time_worked_not_changed_unless_allowed

  # @deprecated - to be removed in next release
  validates :last_known_ticket_status,
    inclusion: {in: RT_TICKET_STATUSES}

  validates :credit_charge, numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
  }, if: :credit_charge  # Credit charge can be null (not set)

  validates :credit_charge, presence: true,  if: :closed?

  # Only validate this type of support is available on create, as this is the
  # only point at which we should prevent users accessing support they are not
  # entitled to; after this point any aspects of the Case and related models
  # might change and make an identical Case not be able to be created today,
  # but this should not invalidate existing Cases.
  validates_with AvailableSupportValidator, on: :create

  validates_with AssociatedModelValidator

  validate :validates_user_assignment

  after_initialize :assign_cluster_if_necessary
  after_initialize :generate_token, on: :create

  before_validation :assign_default_subject_if_unset

  before_create :set_display_id
  after_create :send_new_case_email
  after_update :maybe_send_new_assignee_email

  scope :active, -> { where(state: 'open') }

  scope :assigned_to, ->(user) { where(assignee: user) }
  scope :not_assigned_to, ->(user) { where.not(assignee: user).or(where(assignee: nil)) }

  def to_param
    self.display_id.parameterize.upcase
  end

  def self.find_from_id!(id)
    if /^[0-9]+$/.match(id)  # It's just a numeric ID
      Case.find(id).decorate
    else # It has non-digits in - let's assume it's a display ID
      Case.find_by_display_id!(id&.upcase)
    end
  end

  # @deprecated - to be removed in next release
  def self.request_tracker
    # Note: `rt_interface_class` is a string which we `constantize`, rather
    # than a constant directly, otherwise Rails autoloading in development
    # could leave us holding a reference to an outdated version of the class,
    # which would then cause things to blow up (e.g. see
    # https://stackoverflow.com/a/23008837).
    @rt ||= Rails.configuration.rt_interface_class.constantize.new
  end

  # @deprecated - to be removed in next release
  def update_ticket_status!
    return unless incomplete_rt_ticket?
    self.last_known_ticket_status = associated_rt_ticket.status
    save!
  end

  def time_entry_allowed?
    # Allow if not persisted - e.g. allow time to be initially set for all states
    open? || !persisted?
  end

  def associated_model
    component || service || cluster
  end

  def associated_model_type
    associated_model.readable_model_name
  end

  # @deprecated - to be removed in next release
  def ticket_completed?
    COMPLETED_RT_TICKET_STATUSES.include?(last_known_ticket_status)
  end

  def email_recipients
    site.all_contacts
        .map(&:email)
  end

  def email_reply_subject
    "Re: #{email_subject}"
  end

  def events
    (
      case_comments.select(&:created_at) +  # Note that CasesController#show
        # creates a new, unsaved CaseComment (because the view needs it)
        # so there will be one included in this set without a created_at
        # date. We clearly don't want to include that in the events stream.
      maintenance_windows.map(&:transitions).flatten.select(&:event) +
      case_state_transitions +
      audits
    ).sort_by(&:created_at).reverse!
  end

  def email_subject
    "#{email_identifier} #{ticket_subject}"
  end

  def email_identifier
    if rt_ticket_id
      "[helpdesk.alces-software.com ##{rt_ticket_id}]"
    else
      "[Alces Flight Center #{display_id}]"
    end
  end

  def ticket_subject
    # NOTE: If the format used here ever changes then this may cause new emails
    # sent in relation to an existing Cases to not be threaded with previous
    # emails related to that Case (see
    # https://github.com/alces-software/alces-flight-center/issues/37#issuecomment-358948462
    # for an explanation). If we want to change this format and avoid this
    # consequence then a solution would be to first add a new field for this
    # whole string, and save and use the existing format for existing Cases.
    #
    # FSR using the conditional in `#email_identifier` rather than repeating it
    # here causes Rails to Base64-encode the plain text part of the email, which
    # causes some of our tests to fail...
    if rt_ticket_id
      "#{cluster.name}: #{subject} [#{token}]"
    else
      # With 'new' display IDs we have a cluster hint, so don't include it twice.
      "#{subject} [#{token}]"
    end
  end

  def email_properties
    {
      Cluster: cluster.name,
      Category: category&.name,
      'Issue': issue.name,
      'Associated component': component&.name,
      'Associated service': service&.name,
      Tier: decorate.tier_description,
      Fields: field_hash,
    }.reject { |_k, v| v.nil? }
  end

  def consultancy?
    tier_level >= 3
  end

  def potential_assignees
    User.where(site: site).order(:name) +
        User.where(admin: true).order(:name)
  end

  def assignee=(new_assignee)
    @assignee_changed = true
    super(new_assignee)
  end

  def time_worked=(new_time)
    @time_worked_changed = (new_time != time_worked)
    super(new_time)
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

  # @deprecated - to be removed in next release
  def associated_rt_ticket
    if rt_ticket_id
      @associated_ticket ||= rt.show_ticket(rt_ticket_id)
    else
      nil
    end
  end

  # @deprecated - to be removed in next release
  def rt
    self.class.request_tracker
  end

  def requestor_email
    user.email
  end

  # We generate a short random token to identify each Case within email
  # clients. Without this, similar but distinct Cases can be hard to
  # distinguish in many email clients as they can have identical subjects, as
  # many email clients will collapse different tickets into the same thread due
  # to their similar subjects (see
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

  def send_new_case_email
    CaseMailer.new_case(self).deliver_later
  end

  def maybe_send_new_assignee_email
    return unless @assignee_changed
    return if assignee.nil?
    CaseMailer.change_assignee(self, assignee).deliver_later
  end

  def validates_user_assignment
    return if assignee.nil?
    errors.add(:assignee, 'must belong to this site, or be an admin') unless assignee.site == site or assignee.admin?
  end

  def set_display_id
    return if self.display_id
    # Note: this method is called `before_create`, which is AFTER validation is run.
    # This ensures that the case is valid before we increment the cluster's
    # `case_index` field. Otherwise display IDs could end up non-sequential.

    if self.rt_ticket_id
      self.display_id = "RT#{rt_ticket_id}"
    else
      self.display_id = "#{cluster.shortcode}#{cluster.next_case_index}"
    end
  end

  def has_display_id_when_saved
    # We want to be able to validate the case initially without a display id
    errors.add(:display_id, 'must be present') unless !persisted? or display_id
  end

  def time_worked_not_changed_unless_allowed
    error_condition = !time_entry_allowed? && @time_worked_changed
    errors.add(:time_worked, "must not be changed when case is #{state}") unless !error_condition
  end

  def field_hash
    fields.map do |f|
      f = f.with_indifferent_access
      [f.fetch(:name), f.fetch(:value)]
    end.to_h.symbolize_keys
  end
end
