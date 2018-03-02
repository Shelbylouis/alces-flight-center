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

  scope :unfinished, -> { where.not(state: finished_states) }

  attr_accessor :skip_comments

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

    after_transition any => any do |model|
      # Use send so can keep method private.
      model.send(:add_transition_comment)
    end
  end

  class << self
    def possible_states
      state_machine.states.keys
    end

    def finished_states
      [
        :cancelled,
        :ended,
        :expired,
        :rejected,
      ]
    end
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
    query = TransitionQuery.parse(symbol)
    query ? query.value_for(self) : super
  end

  def respond_to?(symbol, include_all=false)
    super || TransitionQuery.parse(symbol)
  end

  private

  delegate :site, to: :case

  def add_transition_comment
    maintenance_notifier.add_transition_comment(state) unless skip_comments
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

  def validate_precisely_one_associated_model
    errors.add(
      :base, 'precisely one Cluster, Component, or Service can be under maintenance'
    ) unless number_associated_models == 1
  end

  def number_associated_models
    [cluster, component, service].select(&:present?).length
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
