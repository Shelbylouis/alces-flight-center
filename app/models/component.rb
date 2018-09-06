class Component < ApplicationRecord
  include AdminConfig::Component
  include ClusterPart
  include MarkdownColumn(:info)

  belongs_to :component_group
  has_one :cluster, through: :component_group
  has_many :logs

  validates_associated :component_group,
                       :cluster

  validates :info, exclusion: { in: [nil], message: 'can\'t be nil' }
end
