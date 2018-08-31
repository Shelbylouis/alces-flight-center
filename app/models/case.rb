# frozen_string_literal: true

class Case < ApplicationRecord
  include AdminConfig::Case
  include HasStateMachine
  include Filterable

  default_scope { order(created_at: :desc) }

  belongs_to :issue
  belongs_to :cluster

  has_many :case_associations, dependent: :destroy
  has_many :services,
           dependent: :destroy,
           through: :case_associations,
           source: :associated_element,
           source_type: 'Service'

  has_many :components,
           dependent: :destroy,
           through: :case_associations,
           source: :associated_element,
           source_type: 'Component'

  has_many :component_groups,
           dependent: :destroy,
           through: :case_associations,
           source: :associated_element,
           source_type: 'ComponentGroup'

  has_many :clusters,
           dependent: :destroy,
           through: :case_associations,
           source: :associated_element,
           source_type: 'Cluster'

  belongs_to :user
  belongs_to :assignee, class_name: 'User', required: false
  belongs_to :contact, class_name: 'User', required: false

  has_many :maintenance_windows
  has_and_belongs_to_many :logs
  has_many :case_comments
  has_one :change_motd_request, required: false, autosave: true
  has_one :change_request, required: false, validate: true

  has_many :case_state_transitions
  alias_attribute :transitions, :case_state_transitions

  has_one :credit_charge, required: false

  delegate :category, to: :issue
  delegate :site, to: :cluster, allow_nil: true

  state_machine initial: :open do
    audit_trail context: [:requesting_user], initial: false

    state :open  # Open case, still work to do
    state :resolved  # Has been resolved but not yet accounted for commercially
    state :closed  # Has been accounted for commercially, nothing more to do

    event(:resolve) { transition open: :resolved }  # Resolved cases cannot be reopened
    event(:close) { transition resolved: :closed }

  end

  audited only: [
    :assignee_id,
    :contact_id,
    :issue_id,
    :subject,
    :time_worked,
    :tier_level
  ], on: [ :update ]
  has_associated_audits

  validates :display_id, uniqueness: true

  validate :has_display_id_when_saved

  validates :token, presence: true
  validates :subject, presence: true
  validates :rt_ticket_id, uniqueness: true, if: :rt_ticket_id

  validates :fields,
    presence: {unless: :change_motd_request},
    absence: {if: :change_motd_request}
  validates_absence_of :change_motd_request, if: :fields

  validates :tier_level,
    presence: true,
    numericality: {
      only_integer: true,
      # Cases cannot be created for Tier of level 0; Tier 0 support is just
      # providing access to documentation without any action needing to be
      # taken by Alces admins.
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 4,
    }
  validate :validate_tier_level_changes

  validates :time_worked,
            numericality: {
              allow_blank: true,
              greater_than_or_equal_to: 0,
              only_integer: true,  # We store time worked as integer minutes.
            }

  validates :time_worked, presence: true, unless: :open?

  validate :time_worked_not_changed_unless_allowed

  validates :credit_charge, presence: true,  if: :closed?
  validates_associated :credit_charge
  validate :validate_minimum_credit_charge

  # Only validate this type of support is available on create, as this is the
  # only point at which we should prevent users accessing support they are not
  # entitled to; after this point any aspects of the Case and related models
  # might change and make an identical Case not be able to be created today,
  # but this should not invalidate existing Cases.
  validates_with AvailableSupportValidator, on: :create

  validates_with AssociatedModelValidator

  validates_with IssueValidator

  validate :validates_user_assignment

  validate :validate_not_resolved_with_open_cr
  validates :change_request,
            presence: { if: proc { |k| k.tier_level == 4 } },
            absence: { unless: proc { |k| k.tier_level == 4 } }

  after_initialize :assign_cluster_if_necessary
  after_initialize :generate_token, on: :create

  before_validation :assign_default_subject_if_unset

  before_create :set_display_id
  after_create :send_new_case_email, :maybe_set_default_assignee, :set_assigned_contact

  scope :state, ->(state) { where(state: state) }
  scope :active, -> { state('open') }
  scope :inactive, -> { where.not(state: 'open') }

  scope :assigned_to, ->(user) { where(assignee: user) }
  scope :not_assigned_to, ->(user) { where.not(assignee: user).or(where(assignee: nil)) }

  scope :associated_with, lambda { |type, id|
    joins(:case_associations)
      .where(
        case_associations: {
          associated_element_type: type,
          associated_element_id: id,
        }
      )
  }

  # _ parameter to work with URL filtering system
  # Defaults to nil so we can just say `.prioritised`
  # Uses reorder rather than order to overwrite the sorting of default_scope
  scope :prioritised, ->(_=nil) { reorder('last_update ASC NULLS FIRST') }

  def to_param
    display_id.parameterize.upcase
  end

  def self.find_from_id!(id)
    if /^[0-9]+$/.match(id)  # It's just a numeric ID
      Case.find(id).decorate
    else # It has non-digits in - let's assume it's a display ID
      Case.find_by_display_id!(id&.upcase)
    end
  end

  def time_entry_allowed?
    # Allow if not persisted - e.g. allow time to be initially set for all states
    open? || !persisted?
  end

  def associations
    (component_groups + components + services + clusters)
  end

  def associations=(objects)
    %w(Service ComponentGroup Component Cluster).each do |type|
      setter_method = "#{type.pluralize.underscore}=".to_sym
      send(setter_method, objects.select { |o| o.model_name == type })
    end
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
      audits +
      logs +
      [ credit_charge ] +
      (change_request&.transitions || []) +
      collated_association_audits
    ).compact.sort_by(&:created_at).reverse!
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

  def email_recipients
    if issue.administrative?
      []
    else
      site.email_recipients
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
      'Associated components': components.empty? ? nil : components.map(&:name).join(', '),
      'Associated services': services.empty? ? nil : services.map(&:name).join(', '),
      Tier: decorate.tier_description,
      Fields: field_hash,
      'Requested MOTD': change_motd_request&.motd,
    }.compact
  end

  def consultancy?
    tier_level >= 3
  end

  def comments_could_be_enabled?
    # If this condition is met then comments by contacts are enabled iff
    # comments_enabled is true.
    open? && !consultancy? && !issue.administrative?
  end

  def can_create_change_request?
    tier_level == 3 && change_request.nil?
  end

  def resolvable?
    state_transitions.map(&:to_name).include?(:resolved) &&
      !unresolvable_reason
  end

  def unresolvable_reason
    if cr_in_progress?
      return 'This case cannot be resolved as the change request is incomplete.'
    end

    unfinished_mws = maintenance_windows.unfinished.count
    if unfinished_mws.positive?
      return "This case cannot be resolved as there #{unfinished_mws == 1 ? 'is an' : 'are'}
       outstanding maintenance window#{unfinished_mws == 1 ? '': 's'}.".squish
    end

    if time_worked.nil?
      return 'This case cannot be resolved until time worked is added.'
    end

    nil
  end

  def potential_assignees
    User.where(role: :admin)
  end

  def potential_contacts
    site.users.where.not(role: :viewer).order(:name)
  end

  def time_worked=(new_time)
    @time_worked_changed = (new_time != time_worked)
    super(new_time)
  end

  def tier_level=(new_level)
    @tier_level_changed = (new_level != tier_level)
    super(new_level)
  end

  def save!
    # Particularly in tests, rather than in normal controller operation, we might keep this object
    # around after saving and do more things to it.
    # So that the validation on these setters works properly, we need to reset the "changed" state
    # of them all before continuing.
    super
    @time_worked_changed = false
    @tier_level_changed = false
  end

  def tool_fields=(tool_hash)
    tool_hash = tool_hash.deep_symbolize_keys
    tool_type = tool_hash.fetch(:type).to_sym
    handle_tool(tool_type, fields: tool_hash)
  end

  def commenting_enabled_for?(user)
    !CaseCommenting.new(self, user).disabled?
  end

  def cr_charge_applies?
    change_request.present? && change_request.completed?
  end

  def minimum_credit_charge
    cr_charge_applies? ? change_request.credit_charge : 0
  end

  def cr_in_progress?
    change_request.present? && !change_request.finalised?
  end

  def resolution_date
    # NB This assumes that each case will only ever be resolved once
    # If we decide to allow reopening cases then we'll want this to be e.g.
    # transitions.where(event: 'resolve').last
    transitions.find_by_event('resolve')&.created_at
  end

  def first_admin_comment
    @first_admin_comment ||= case_comments.joins(:user)
                 .where(users: { role: 'admin' })
                 .order(:created_at)
                 .first
  end

  def time_to_first_response
    return unless first_admin_comment
    created_at.business_time_until(
      first_admin_comment.created_at
    )
  end

  def time_since_last_update
    return unless last_update
    # In which we redefine a "day" to be 8 hours long.
    raw = last_update.business_time_until(Time.current)

    days = (raw / 8.hours).floor
    raw -= (8 * days.hours).seconds

    hours = (raw / 1.hour).floor
    raw -= hours.hours.seconds

    minutes = (raw / 1.minutes).floor
    raw -= minutes.minutes.seconds

    days.days + hours.hours + minutes.minutes + raw.seconds
  end

  def allowed_to_comment?
    [self.assignee, self.contact].include?(current_user)
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

  def collated_association_audits
    # We assume that no user will make two separate changes to the associations
    # within a second, in order to collate their changes into one lump to
    # provide a summary for use in an event card.
    associated_audits
        .where(auditable_type: 'CaseAssociation')
        .group_by do |a|
          [a.user_id, a.created_at.change(usec: 0)]
        end
        .map do |key, audits|
          CollatedCaseAssociationAudit.new(*key, audits)
        end
  end

  def assign_cluster_if_necessary
    return if cluster
    self.cluster = components.first.cluster if components.present?
    self.cluster = services.first.cluster if services.present?
  end

  def assign_default_subject_if_unset
    self.subject ||= issue.default_subject
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

  def maybe_set_default_assignee
    if assignee.nil? && !site.default_assignee.nil?
      transaction do # to make sure audits.last is our assignee change
        self.assignee = site.default_assignee
        save!
        la = audits.last
        # This will show as 'Flight Center' rather than the customer's name
        # - the latter would be misleading here since customers can't assign
        # cases to people!
        # NB Audited.audit_class.as_user(nil) does not work since it then gets
        # the user from current_user anyway :(
        la.user = nil
        la.save!
      end
    end
  end

  def set_assigned_contact
    if open?
      contact = if current_user.nil? || current_user.admin?
                  site.primary_contact
                else
                  current_user
                end

      unless contact.nil?
        transaction do
          self.contact = contact
          save!
          la = audits.last
          la.user = nil
          la.save!
        end
      end
    end
  end

  def validates_user_assignment
    return if assignee.nil?
    errors.add(:assignee, 'must belong to this site, or be an admin') unless (assignee.site == site) || assignee.admin?
  end

  def set_display_id
    return if display_id
    # Note: this method is called `before_create`, which is AFTER validation is run.
    # This ensures that the case is valid before we increment the cluster's
    # `case_index` field. Otherwise display IDs could end up non-sequential.

    self.display_id = if rt_ticket_id
      "RT#{rt_ticket_id}"
    else
      "#{cluster.shortcode}#{cluster.next_case_index}"
                      end
  end

  def has_display_id_when_saved
    # We want to be able to validate the case initially without a display id
    errors.add(:display_id, 'must be present') unless !persisted? || display_id
  end

  def time_worked_not_changed_unless_allowed
    error_condition = !time_entry_allowed? && @time_worked_changed
    errors.add(:time_worked, "must not be changed when case is #{state}") if error_condition
  end

  def validate_tier_level_changes
    error_condition = @tier_level_changed && persisted? && !open?
    errors.add(:tier_level, "cannot be changed when a case is #{state}") if error_condition
  end

  def validate_not_resolved_with_open_cr
    error_condition = resolved? && cr_in_progress?
    errors.add(:state, 'cannot be resolved with an open change request') if error_condition
  end

  def validate_minimum_credit_charge
    error_condition = closed? &&
                      cr_charge_applies? &&
                      (
                        credit_charge.nil? ||
                        credit_charge.amount < change_request.credit_charge
                      )

    errors.add(:credit_charge, "cannot be less than attached CR charge of #{change_request.credit_charge}") if error_condition
  end

  def field_hash
    return nil unless fields
    fields.map do |f|
      f = f.with_indifferent_access
      [f.fetch(:name), f.fetch(:value)]
    end.to_h.symbolize_keys
  end

  def handle_tool(type, fields:)
    case type
    when :motd
      build_change_motd_request(
        fields.slice(:motd)
      )
    else
      raise "Unknown type: '#{type}'"
    end
  end
end
