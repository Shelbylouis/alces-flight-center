class Component < ApplicationRecord
  include AdminConfig::Component
  include ClusterPart

  belongs_to :component_group
  has_one :cluster, through: :component_group
  has_many :logs

  validates_associated :component_group,
                       :cluster

  def component_type
    # TODO
    'NOT_YET_IMPLEMENTED'
  end
end
