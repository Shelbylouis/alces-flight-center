class ChangeRequest < ApplicationRecord
  belongs_to :case

  delegate :site, to: :case

  after_create :ensure_case_is_tier_4

  state_machine initial: :draft do
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

  validates :details, presence: true

  private

  def ensure_case_is_tier_4
    self.case.tier_level = 4
    self.case.save!
  end

end
