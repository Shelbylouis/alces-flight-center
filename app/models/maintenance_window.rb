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

    event :request do
      transition new: :requested
    end
    after_transition new: :requested do |model|
      model.add_maintenance_requested_comment
    end

    event :confirm do
      transition requested: :confirmed
    end
    after_transition requested: :confirmed do |model|
      model.add_maintenance_confirmed_comment
    end

    event :cancel do
      transition [:new, :requested] => :cancelled
    end
    after_transition any => :cancelled do |model|
      model.add_maintenance_cancelled_comment
    end

    event :reject do
      transition requested: :rejected
    end
    after_transition requested: :rejected do |model|
      model.add_maintenance_rejected_comment
    end

    event :expire do
      transition [:new, :requested] => :expired
    end
    after_transition any => :expired do |model|
      model.add_maintenance_expired_comment
    end

    event :start do
      transition confirmed: :started
    end
    after_transition confirmed: :started do |model|
      model.add_maintenance_started_comment
    end

    event :end do
      transition started: :ended
    end
    after_transition started: :ended do |model|
      model.add_maintenance_ended_comment
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

  def add_maintenance_requested_comment
    comment = <<-EOF.squish
      Maintenance requested for #{associated_model.name} by #{requested_by.name}; to
      proceed this maintenance must be confirmed on the cluster dashboard:
      #{cluster_dashboard_url}.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_confirmed_comment
    comment = <<~EOF.squish
      Maintenance of #{associated_model.name} confirmed by
      #{confirmed_by.name}; this #{associated_model.readable_model_name}
      is now under maintenance.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_cancelled_comment
    comment = <<~EOF.squish
      Request for maintenance of #{associated_model.name} cancelled by
      #{cancelled_by.name}.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_rejected_comment
    comment =
      "Maintenance of #{associated_model.name} rejected by #{rejected_by.name}"
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_expired_comment
    comment = <<~EOF.squish
      Request for maintenance of #{associated_model.name} was not confirmed
      before requested start; this maintenance has been automatically
      cancelled.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_started_comment
    comment = "confirmed maintenance of #{associated_model.name} started."
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_ended_comment
    comment = "#{associated_model.name} is no longer under maintenance."
    add_rt_ticket_correspondence(comment)
  end

  def method_missing(symbol, *args)
    super unless symbol =~ /^([a-z]+)_(at|by)$/
    state = $1.to_sym
    property = $2.to_sym
    super unless possible_states.include?(state)
    last_transition_property(state: state, property: property)
  end

  private

  delegate :add_rt_ticket_correspondence, :site, to: :case

  # Picked up by state_machines-audit_trail due to `context` setting above, and
  # used to automatically set user who instigated the transition in created
  # MaintenanceWindowStateTransition (for transitions instigated by user).
  # Refer to
  # https://github.com/state-machines/state_machines-audit_trail#example-5---store-advanced-method-results.
  def user(transition)
    transition.args&.first
  end

  def validate_precisely_one_associated_model
    errors.add(
      :base, 'precisely one Cluster, Component, or Service can be under maintenance'
    ) unless number_associated_models == 1
  end

  def number_associated_models
    [cluster, component, service].select(&:present?).length
  end

  def cluster_dashboard_url
    Rails.application.routes.url_helpers.cluster_url(associated_cluster)
  end

  def possible_states
    self.class.state_machine.states.keys
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
