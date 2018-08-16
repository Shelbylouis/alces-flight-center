class Note < ApplicationRecord
  include MarkdownDescription
  include BelongsToCluster
  include AdminConfig::Note

  VISIBILITIES = %w(customer engineering).freeze

  belongs_to :cluster
  has_one :site, through: :cluster

  validates :description, presence: true
  validates :visibility, inclusion: { in: VISIBILITIES }, presence: true

  VISIBILITIES.each do |v|
    scope v, ->{ where(visibility: v) }
  end

  def visibilities_enum
    VISIBILITIES
  end
end
