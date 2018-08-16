class MaintenanceWindow < ApplicationRecord
  include AdminConfig::MaintenanceWindow
  include HasStateMachine

  default_scope { order(created_at: :desc) }
  belongs_to :case
  delegate :site, to: :case

  has_many :maintenance_window_associations, dependent: :destroy
  has_many :services,
           dependent: :destroy,
           through: :maintenance_window_associations,
           source: :associated_element,
           source_type: 'Service'

  has_many :components,
           dependent: :destroy,
           through: :maintenance_window_associations,
           source: :associated_element,
           source_type: 'Component'

  has_many :component_groups,
           dependent: :destroy,
           through: :maintenance_window_associations,
           source: :associated_element,
           source_type: 'ComponentGroup'

  has_many :clusters,
           dependent: :destroy,
           through: :maintenance_window_associations,
           source: :associated_element,
           source_type: 'Cluster'

  delegate :cluster, to: :case

  has_many :maintenance_window_state_transitions
  alias_attribute :transitions, :maintenance_window_state_transitions

  validates_presence_of :requested_start
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates_with Validator

  scope :unfinished, -> { where.not(state: finished_states) }

  attr_accessor :legacy_migration_mode

  state_machine initial: :new do
    audit_trail context: [:user, :requested_start, :duration]

    state :new
    state :requested
    state :confirmed
    state :started
    state :ended
    state :rejected
    state :cancelled
    state :expired

    end_transition = Proc.new { transition started: :ended }

    event(:request) { transition new: :requested }
    event(:confirm) { transition [:requested, :expired] => :confirmed }
    event(:mandate) { transition new: :confirmed }
    event(:cancel) { transition [:new, :requested, :expired] => :cancelled }
    event(:reject) { transition [:requested, :expired] => :rejected }
    event(:end, &end_transition)
    event(:extend_duration) { transition confirmed: :confirmed, started: :started }
    event(:auto_expire) { transition [:new, :requested] => :expired }
    event(:auto_start) { transition confirmed: :started }
    event(:auto_end, &end_transition)

    after_transition any => any do |model, transition|
      # Use send so can keep method private.
      model.send(:add_transition_comment, transition.event)
    end

    after_transition on: :extend_duration, do: :reset_maintenance_ending_soon_email_flag
  end

  class << self
    # A maintenance window is 'finished' once it has reached a state which it
    # cannot transition out of.
    def finished_states
      possible_states.select { |state| cannot_leave_state?(state) }
    end

    private

    def cannot_leave_state?(state)
      MaintenanceWindow.new(state: state).state_paths.empty?
    end
  end

  def associated_models
    component_groups + components + services + clusters
  end

  def expected_end
    duration.business_days.after(requested_start)
  end

  def user_facing_state
    case state.to_sym
    when :new, :requested, :expired
      'requested'
    when :confirmed
      'scheduled'
    when :started
      'ongoing'
    when *MaintenanceWindow.finished_states
      'finished'
    end
  end

  def method_missing(symbol, *args)
    query = TransitionQuery.parse(symbol)
    query ? query.value_for(self) : super
  end

  def respond_to_missing?(symbol, include_all=false)
    TransitionQuery.parse(symbol)
  end

  def set_maintenance_ending_soon_email_flag
    self.update!(maintenance_ending_soon_email_sent: true)
  end

  def reset_maintenance_ending_soon_email_flag
    self.update!(maintenance_ending_soon_email_sent: false)
  end

  private

  def add_transition_comment(event)
    unless invalid? || legacy_migration_mode
      maintenance_notifier.add_transition_comment(event)
    end
  end

  # Picked up by state_machines-audit_trail due to `context` setting above, and
  # used to automatically set user who instigated the transition in created
  # MaintenanceWindowStateTransition (for transitions instigated by user).
  # Refer to
  # https://github.com/state-machines/state_machines-audit_trail#example-5---store-advanced-method-results.
  def user(transition)
    transition.args&.first
  end

  def maintenance_notifier
    @maintenance_notifier ||= MaintenanceNotifier.new(self)
  end

  # Represents a query for the value of a particular property of a
  # MaintenanceWindow when it last transitioned to a particular state.
  TransitionQuery = Struct.new(:state, :property) do
    REGEX = /^([a-z]+)_(at|by)$/

    def self.parse(symbol)
      return false unless symbol =~ REGEX
      state = $1.to_sym
      property = $2.to_sym
      return false unless MaintenanceWindow.possible_states.include?(state)
      new(state, property)
    end

    def value_for(window)
      transition = last_transition_to_state(window)
      case property
      when :at
        transition&.created_at
      when :by
        transition&.user
      end
    end

    private

    def last_transition_to_state(window)
      window.transitions.where(to: state).last
    end
  end
end
