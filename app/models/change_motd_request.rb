class ChangeMotdRequest < ApplicationRecord
  include HasStateMachine

  validates_presence_of :motd, :state
  belongs_to :case

  has_many :change_motd_request_state_transitions
  alias_attribute :transitions, :change_motd_request_state_transitions

  delegate :site, :cluster, to: :case

  state_machine initial: :unapplied do
    audit_trail context: [:user], initial: false

    state :unapplied
    state :applied

    event :apply { transition any => :applied }

    after_transition(on: :apply, &:handle_apply)
  end

  # Picked up by state_machines-audit_trail due to `context` setting above, and
  # used to automatically set user who instigated the transition in created
  # ChangeMotdRequestStateTransition.  Refer to
  # https://github.com/state-machines/state_machines-audit_trail#example-5---store-advanced-method-results.
  def user(transition)
    transition.args&.first
  end

  def handle_apply(_transition)
    cluster.update!(motd: self.motd)
  end
end
