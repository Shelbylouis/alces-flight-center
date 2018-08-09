class ChangeRequest < ApplicationRecord
  include MarkdownDescription

  belongs_to :case

  has_many :change_request_state_transitions
  alias_attribute :transitions, :change_request_state_transitions

  delegate :site, to: :case

  state_machine initial: :draft do
    audit_trail context: [:requesting_user], initial: false

    state :draft
    state :awaiting_authorisation
    state :declined
    state :in_progress
    state :in_handover
    state :completed
    state :cancelled

    event(:propose) { transition draft: :awaiting_authorisation }
    event(:cancel) { transition draft: :cancelled }
    event(:decline) { transition awaiting_authorisation: :declined }
    event(:authorise) { transition awaiting_authorisation: :in_progress }
    event(:request_changes) { transition awaiting_authorisation: :draft }
    event(:handover) { transition in_progress: :in_handover }
    event(:complete) { transition in_handover: :completed }

  end

  validates :credit_charge,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
            }

  validates :description, presence: true

  def finalised?
    completed? || declined? || cancelled?
  end

  private

  def requesting_user(transition)
    transition.args&.first
  end

end
