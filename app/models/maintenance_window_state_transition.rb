class MaintenanceWindowStateTransition < ApplicationRecord
  belongs_to :maintenance_window
  belongs_to :user, required: false

  delegate :site, to: :maintenance_window

  validates_presence_of :user, unless: :automatic_transition?
  validates_absence_of :user, if: :automatic_transition?
  validate :validate_user_can_initiate

  private

  AUTOMATIC_EVENTS = [
    :auto_end,
    :auto_expire,
    :auto_start,
    nil,
  ]

  def automatic_transition?
    AUTOMATIC_EVENTS.include?(event&.to_sym)
  end

  def validate_user_can_initiate
    case event&.to_sym
    when :request, :mandate, :cancel
      errors.add(:user, 'must be an admin') unless user&.admin?
    when :reject
      errors.add(:user, 'must be a site contact') unless user&.contact?
    end
  end
end
