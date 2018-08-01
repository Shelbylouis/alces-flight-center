class ClusterCheck < ApplicationRecord
  include BelongsToCluster
  include AdminConfig::ClusterCheck

  belongs_to :cluster
  belongs_to :check

  has_many :check_results

  validates :cluster, presence: true
  validates :check, presence: true

  delegate :name, to: :check, allow_nil: true
  delegate :check_category, to: :check
  delegate :site, to: :cluster
end
