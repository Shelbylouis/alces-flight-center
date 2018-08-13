class CheckResult < ApplicationRecord
  include MarkdownColumn(:comment)

  belongs_to :cluster_check
  belongs_to :user

  validates :date, presence: true
  validates :result, presence: true
  validates :cluster_check, presence: true
  validates :user, presence: true

  delegate :check_category, to: :cluster_check
  delegate :site, to: :cluster_check
end
