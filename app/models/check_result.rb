class CheckResult < ApplicationRecord
  belongs_to :cluster_check
  belongs_to :user

  delegate :check_category, to: :cluster_check
end
