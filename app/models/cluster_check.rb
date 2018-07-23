class ClusterCheck < ApplicationRecord
  belongs_to :cluster
  belongs_to :check

  has_many :check_results

  delegate :id, to: :check
  delegate :name, to: :check
  delegate :check_category, to: :check
end
