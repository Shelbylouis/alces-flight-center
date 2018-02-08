
class ClusterLog < ApplicationRecord
  belongs_to :cluster
  belongs_to :engineer, class_name: 'User', foreign_key: "user_id"

  validates :details, presence: true
end

