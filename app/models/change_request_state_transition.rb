class ChangeRequestStateTransition < ApplicationRecord
  belongs_to :change_request
  belongs_to :user

  delegate :site, to: :change_request

  alias_attribute :requesting_user, :user

  validates_presence_of :user
  validate :validate_user_can_initiate

  private

  def validate_user_can_initiate
    case event&.to_sym
    when :propose, :handover, :cancel
      errors.add(:user, 'must be an admin') unless user&.admin?
    when :authorise, :decline, :complete, :request_changes
      errors.add(:user, 'must be a contact') unless user&.contact?
    end
  end
end
