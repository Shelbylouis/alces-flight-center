class ClusterCheck < ApplicationRecord
  belongs_to :cluster
  belongs_to :check

  has_many :check_results

  delegate :id, to: :check, allow_nil: true
  delegate :name, to: :check, allow_nil: true
  delegate :check_category, to: :check
  delegate :site, to: :cluster
end
