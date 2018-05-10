class CaseStateTransition < ApplicationRecord
  belongs_to :case
  belongs_to :user
  alias_attribute :requesting_user, :user

  delegate :site, to: :case

  validates_presence_of :user
  validate :validate_user_can_initiate

  private

  def validate_user_can_initiate
    case event&.to_sym
    when :resolve, :close
      errors.add(:user, 'must be an admin') unless user&.admin?
    end
  end
end
