class ChangeRequest < ApplicationRecord
  include MarkdownDescription

  belongs_to :case

  has_many :change_request_state_transitions
  alias_attribute :transitions, :change_request_state_transitions

  delegate :site, to: :case

  after_create :ensure_case_is_tier_4

  state_machine initial: :draft do
    audit_trail context: [:requesting_user], initial: false

    state :draft
    state :awaiting_authorisation
    state :declined
    state :in_progress
    state :in_handover
    state :completed

    event(:propose) { transition draft: :awaiting_authorisation }
    event(:decline) { transition awaiting_authorisation: :declined }
    event(:authorise) { transition awaiting_authorisation: :in_progress }
    event(:handover) { transition in_progress: :in_handover }
    event(:complete) { transition in_handover: :completed }

  end

  validates :credit_charge,
            presence: true,
            numericality: {
                only_integer: true,
                minimum: 0
            }

  validates :description, presence: true

  private

  def requesting_user(transition)
    transition.args&.first
  end

  def ensure_case_is_tier_4
    self.case.tier_level = 4
    self.case.save!
  end

end
