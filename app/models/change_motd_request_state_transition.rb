class ChangeMotdRequestStateTransition < ApplicationRecord
  belongs_to :change_motd_request
  belongs_to :user

  delegate :site, to: :change_motd_request

  validates_presence_of :user
  validate :validate_user_is_admin

  private

  def validate_user_is_admin
    errors.add(:user, 'must be an admin') unless user&.admin?
  end
end
