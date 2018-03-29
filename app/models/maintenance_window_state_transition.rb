class MaintenanceWindowStateTransition < ApplicationRecord
  belongs_to :maintenance_window
  belongs_to :user, required: false

  delegate :site, to: :maintenance_window

  validates_presence_of :user, unless: :automatic_transition?
  validates_absence_of :user, if: :automatic_transition?
  validate :validate_user_can_initiate

  private

  def automatic_transition?
    initial_transition? || event.start_with?('auto_')
  end

  def initial_transition?
    # A `nil` event <=> this is the initial transition to `new` automatically
    # created when a MaintenanceWindow is created.
    event.nil?
  end

  def validate_user_can_initiate
    case event&.to_sym
    when :request, :mandate, :cancel, :end
      errors.add(:user, 'must be an admin') unless user&.admin?
    when :reject
      errors.add(:user, 'must be a site contact') unless user&.contact?
    end
  end
end
