class CheckResult < ApplicationRecord
  belongs_to :cluster_check
  belongs_to :user
end
