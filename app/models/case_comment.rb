class CaseComment < ApplicationRecord
  belongs_to :user
  belongs_to :case

  delegate :site, to: :case, allow_nil: true

  validates :user, presence: true
  validates :case, presence: true

  validates :text, length: { minimum: 2}
end
