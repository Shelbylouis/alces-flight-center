class MaintenanceWindow < ApplicationRecord
  belongs_to :case
  belongs_to :cluster, required: false
  belongs_to :component, required: false
  belongs_to :service, required: false

  has_many :maintenance_window_state_transitions
  alias_attribute :transitions, :maintenance_window_state_transitions

  validate :validate_precisely_one_associated_model
  validates_presence_of :requested_start
  validates_presence_of :requested_end

  state_machine initial: :new do
    audit_trail context: :user

    state :new
    state :requested
    state :confirmed
    state :started
    state :ended
    state :rejected
    state :cancelled
    state :expired

    event :request { transition new: :requested }
    event :confirm { transition requested: :confirmed }
    event :cancel { transition [:new, :requested] => :cancelled }
    event :reject { transition requested: :rejected }
    event :expire { transition [:new, :requested] => :expired }
    event :start { transition confirmed: :started }
    event :end { transition started: :ended }

    after_transition any => any do |model, transition|
      new_state = transition.to_name
      # Use send so can keep method private.
      model.send(:add_transition_comment, new_state)
    end
  end

  def self.possible_states
    state_machine.states.keys
  end

  alias_method :in_progress?, :confirmed?

  def associated_model
    component || service || cluster
  end

  def associated_model=(model)
    case model
    when Cluster
      self.cluster = model
    when Component
      self.component = model
    when Service
      self.service = model
    end
  end

  def associated_cluster
    cluster || associated_model.cluster
  end

  def method_missing(symbol, *args)
    super unless symbol =~ /^([a-z]+)_(at|by)$/
    state = $1.to_sym
    property = $2.to_sym
    super unless self.class.possible_states.include?(state)
    last_transition_property(state: state, property: property)
  end

  private

  delegate :site, to: :case
  delegate :add_transition_comment, to: :maintenance_notifier

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

  def validate_precisely_one_associated_model
    errors.add(
      :base, 'precisely one Cluster, Component, or Service can be under maintenance'
    ) unless number_associated_models == 1
  end

  def number_associated_models
    [cluster, component, service].select(&:present?).length
  end

  def last_transition_property(state:, property:)
    transition = last_transition_to_state(state)
    case property
    when :at
      transition&.created_at
    when :by
      transition&.user
    end
  end

  def last_transition_to_state(state)
    transitions.where(to: state).last
  end
end
