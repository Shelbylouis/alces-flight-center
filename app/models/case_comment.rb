class CaseComment < ApplicationRecord
  belongs_to :user
  belongs_to :case

  delegate :site, to: :case, allow_nil: true

  validates :user, presence: true
  validates :case, presence: true

  validates :text, length: { minimum: 2}

  validate :valid_user, on: :create

  private

  def valid_user
    errors.add(:user, 'does not have permission to post a comment on this case') unless user.admin? || user.site == site
  end
end
