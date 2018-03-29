class MaintenanceWindowStateTransition < ApplicationRecord
  belongs_to :maintenance_window
  belongs_to :user, required: false

  delegate :site, to: :maintenance_window

  validates_presence_of :user, if: :user_initiated_transition?
  validates_absence_of :user, unless: :user_initiated_transition?
  validate :validate_user_can_initiate

  private

  USER_INITIATED_STATES = [
    :cancelled,
    :confirmed,
    :rejected,
    :requested,
  ].freeze

  def user_initiated_transition?
    USER_INITIATED_STATES.include?(to.to_sym)
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
